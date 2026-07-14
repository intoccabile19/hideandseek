extends Node

@export var whistle_stream: AudioStream = null
@export var chirp_stream: AudioStream = null
@export var footstep_stream: AudioStream = null
@export var heartbeat_stream: AudioStream = null

var _heartbeat_timer: float = 0.0
var _heartbeat_interval: float = 1.5 # seconds between beats
var _current_alert: float = 0.0

var master_volume: float = 0.5

func _ready() -> void:
	# Start master bus volume at 50% (baseline 0.0 dB)
	set_master_volume(0.5)

func set_master_volume(value: float) -> void:
	master_volume = value
	# value goes 0.0 to 1.0. 
	# 0.5 maps to 0.0 dB (our baseline).
	# 1.0 maps to +12.0 dB (extra loud!).
	# 0.0 maps to -80.0 dB (mute).
	var db: float = 0.0
	if value < 0.05:
		db = -80.0 # Muted
	else:
		db = (value - 0.5) * 24.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _process(delta: float) -> void:
	# Count down heartbeat timer
	_heartbeat_timer += delta
	if _heartbeat_timer >= _heartbeat_interval:
		_heartbeat_timer = 0.0
		_play_heartbeat_thud()

func _play_heartbeat_thud() -> void:
	# Boosted volume scaling based on alert level (from audible -6dB up to loud +4dB)
	var volume: float = lerp(-6.0, 4.0, _current_alert)
	
	if heartbeat_stream:
		# Play custom sound if loaded
		_play_stream(heartbeat_stream, volume)
	else:
		# Procedural double heartbeat thud (lub-dub) using audible mid-bass frequencies (110Hz - 130Hz)
		_play_synthetic_beep(130.0, 0.08, volume)
		get_tree().create_timer(0.18).timeout.connect(
			func():
				_play_synthetic_beep(110.0, 0.12, volume - 2.0)
		)

func update_heartbeat(alert_level: float) -> void:
	_current_alert = clamp(alert_level, 0.0, 1.0)
	_heartbeat_interval = lerp(1.5, 0.45, _current_alert)

func play_whistle() -> void:
	if whistle_stream:
		_play_stream(whistle_stream, 0.0)
	else:
		# Synthetic whistle beep (loud and clear)
		_play_synthetic_beep(780.0, 0.22, 0.0)

func play_chirp(pos: Vector3) -> void:
	if chirp_stream:
		_play_stream_3d(chirp_stream, pos, 0.0)
	else:
		# Play toddler chirp as a clear 2D sound at 0dB (so player can hear it anywhere)
		_play_synthetic_beep(1200.0, 0.07, 0.0)

func play_footstep(pos: Vector3, volume_db: float = 0.0) -> void:
	if footstep_stream:
		_play_stream_3d(footstep_stream, pos, volume_db)
	else:
		# Scale volume dynamically based on horizontal X distance to the player
		var dist_x: float = 30.0
		if is_instance_valid(FamilyManager.player):
			dist_x = abs(pos.x - FamilyManager.player.global_position.x)
		
		# Louder footsteps that fade as the seeker gets further on the X axis
		var vol: float = clamp(lerp(2.0, -16.0, dist_x / 25.0), -24.0, 2.0)
		_play_synthetic_beep(220.0, 0.09, vol)

func play_interact(pos: Vector3) -> void:
	# Quick pleasant two-tone synth beep
	_play_synthetic_beep(600.0, 0.08, -2.0)
	get_tree().create_timer(0.08).timeout.connect(
		func():
			_play_synthetic_beep(850.0, 0.1, 0.0)
	)

func play_object_move(pos: Vector3) -> void:
	# Low industrial mechanical sliding hum
	_play_synthetic_beep(110.0, 0.6, -4.0)

func play_scrape(pos: Vector3) -> void:
	# Short friction scraping tone for pushing crates
	_play_synthetic_beep(185.0, 0.12, -8.0)

func _play_stream(stream: AudioStream, vol_db: float) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.volume_db = vol_db
	player.play()
	player.finished.connect(player.queue_free)

func _play_stream_3d(stream: AudioStream, pos: Vector3, vol_db: float) -> void:
	var player := AudioStreamPlayer3D.new()
	add_child(player)
	player.global_position = pos
	player.stream = stream
	player.volume_db = vol_db
	player.max_distance = 30.0
	player.play()
	player.finished.connect(player.queue_free)

func _play_synthetic_beep(frequency: float, duration: float, volume_db: float = 0.0) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = duration
	
	player.stream = generator
	player.volume_db = volume_db
	player.play()
	
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		var sample_rate: float = generator.mix_rate
		var total_frames: int = int(sample_rate * duration)
		var phase: float = 0.0
		var phase_increment: float = 2.0 * PI * frequency / sample_rate
		
		var frames_to_fill: int = playback.get_frames_available()
		var frames_written: int = 0
		while frames_written < total_frames:
			var chunk: int = min(frames_to_fill, total_frames - frames_written)
			if chunk <= 0:
				break
			var buffer := PackedVector2Array()
			buffer.resize(chunk)
			for i in range(chunk):
				# Linear decay envelope to prevent clicks (amplitude boosted to 0.85)
				var env: float = 1.0 - (float(frames_written + i) / total_frames)
				var val: float = sin(phase) * env * 0.85
				buffer[i] = Vector2(val, val)
				phase += phase_increment
			playback.push_buffer(buffer)
			frames_written += chunk
			frames_to_fill = playback.get_frames_available()
			
	get_tree().create_timer(duration + 0.1).timeout.connect(player.queue_free)

func _play_synthetic_beep_3d(frequency: float, duration: float, pos: Vector3, volume_db: float = 0.0) -> void:
	var player := AudioStreamPlayer3D.new()
	add_child(player)
	player.global_position = pos
	player.max_distance = 30.0
	
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = duration
	
	player.stream = generator
	player.volume_db = volume_db
	player.play()
	
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		var sample_rate: float = generator.mix_rate
		var total_frames: int = int(sample_rate * duration)
		var phase: float = 0.0
		var phase_increment: float = 2.0 * PI * frequency / sample_rate
		
		var frames_to_fill: int = playback.get_frames_available()
		var frames_written: int = 0
		while frames_written < total_frames:
			var chunk: int = min(frames_to_fill, total_frames - frames_written)
			if chunk <= 0:
				break
			var buffer := PackedVector2Array()
			buffer.resize(chunk)
			for i in range(chunk):
				var env: float = 1.0 - (float(frames_written + i) / total_frames)
				var val: float = sin(phase) * env * 0.85
				buffer[i] = Vector2(val, val)
				phase += phase_increment
			playback.push_buffer(buffer)
			frames_written += chunk
			frames_to_fill = playback.get_frames_available()
			
	get_tree().create_timer(duration + 0.1).timeout.connect(player.queue_free)
