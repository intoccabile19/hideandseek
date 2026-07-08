---
name: hide_and_seek_game_rules
description: "Rules and design patterns for building the Hide and Seek game in Godot 4.6.3"
---
# Hide and Seek Game Rules & Design Patterns

This skill file defines the design patterns, code structures, and rules specifically for our Hide and Seek game. When triggered, it helps guide Antigravity on implementation details.

## Core Architecture Pattern
- **State Machine**: All gameplay entities (Seeker, Hider) must use a State Machine pattern for behavior.
- **Signals**: Use Godot's built-in signal system to communicate between gameplay elements (e.g., when a player is caught).
- **Proximity Detection**: Use Area3D or Area2D for detection triggers.
