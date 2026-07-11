# run_tests.ps1
$GodotPath = "C:\Godot\Godot_v4.6.3-stable_win64.exe"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Godot 4.6.3 Project Verification Suite" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Update Project Cache & Compile Scripts
Write-Host "Updating Godot project cache and assets..." -ForegroundColor Yellow
$importProcess = Start-Process -FilePath $GodotPath -ArgumentList "--headless", "--editor", "--quit", "--path", "." -NoNewWindow -PassThru -Wait

# 2. Running Unit Tests via test_runner.gd
Write-Host "`nRunning Headless Test Runner..." -ForegroundColor Yellow

$OutFile = "test_out.log"
$ErrFile = "test_err.log"

$testProcess = Start-Process -FilePath $GodotPath -ArgumentList "--headless", "--path", ".", "-s", "test_runner.gd" -NoNewWindow -PassThru -RedirectStandardOutput $OutFile -RedirectStandardError $ErrFile

try {
	$testProcess | Wait-Process -Timeout 15 -ErrorAction Stop
} catch {
	Write-Host "`n[ERROR] Test runner hung and timed out after 15 seconds! Terminating..." -ForegroundColor Red
	Stop-Process -Id $testProcess.Id -Force
	Exit 1
}

Start-Sleep -Milliseconds 100

if (Test-Path $OutFile) {
	Get-Content $OutFile
	Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}
if (Test-Path $ErrFile) {
	$errContent = Get-Content $ErrFile
	if ($errContent) {
		Write-Host "`n[stderr output]:" -ForegroundColor DarkRed
		Write-Host $errContent -ForegroundColor Red
	}
	Remove-Item $ErrFile -Force -ErrorAction SilentlyContinue
}

if ($testProcess.ExitCode -ne 0) {
	Write-Host "`n[ERROR] Test execution failed with exit code $($testProcess.ExitCode)." -ForegroundColor Red
	Exit 1
}

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "[SUCCESS] All tests and validations passed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Exit 0

