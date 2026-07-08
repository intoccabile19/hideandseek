# run_tests.ps1
$GodotPath = "C:\Godot\Godot_v4.6.3-stable_win64.exe"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Godot 4.6.3 Project Verification Suite" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Running Unit Tests via test_runner.gd
Write-Host "Running Headless Test Runner..." -ForegroundColor Yellow

$OutFile = "test_out.log"
$ErrFile = "test_err.log"

$testProcess = Start-Process -FilePath $GodotPath -ArgumentList "--headless", "--path", ".", "-s", "test_runner.gd" -NoNewWindow -PassThru -Wait -RedirectStandardOutput $OutFile -RedirectStandardError $ErrFile

if (Test-Path $OutFile) {
	Get-Content $OutFile
	Remove-Item $OutFile
}
if (Test-Path $ErrFile) {
	$errContent = Get-Content $ErrFile
	if ($errContent) {
		Write-Host "`n[stderr output]:" -ForegroundColor DarkRed
		Write-Host $errContent -ForegroundColor Red
	}
	Remove-Item $ErrFile
}

if ($testProcess.ExitCode -ne 0) {
	Write-Host "`n[ERROR] Test execution failed with exit code $($testProcess.ExitCode)." -ForegroundColor Red
	Exit 1
}

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "[SUCCESS] All tests and validations passed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Exit 0

