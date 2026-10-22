@echo off
setlocal EnableExtensions

set "DEST=\\172.16.56.11\Aetram Trades\RMS\Prakash\DP Process\HTML\Margin New-20102026"
set "BASE=\\172.16.56.11\Aetram Trades\RMS\1 Trade Process"

if not exist "%DEST%" mkdir "%DEST%"

for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy"') do set "YEAR=%%A"
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format MM"') do set "MONTH=%%A"
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format MMM"') do set "MON=%%A"

set "MONTHNAME=%MONTH% %MON% %YEAR%"

echo ==========================================
echo Copying Latest Bhavcopy Files
echo Destination: %DEST%
echo ==========================================

REM NSE FO
call :CopyLatest "2 NSE-BSE-FO" "BhavCopy_NSE_FO_0_0_0_*_F_0000.csv" "nfo_bhavcopy.csv"

REM BSE FO
call :CopyLatest "2 NSE-BSE-FO" "BhavCopy_BSE_FO_0_0_0_*_F_0000.csv" "bfo_bhavcopy.csv"

REM MCX CO
call :CopyLatest "3 MCX" "Bhavcopy_MCX_CO_0_0_0_*_F_0000.csv" "mcx_bhavcopy.csv"

REM NSE CDS
call :CopyLatest "5 NSE-BSE-CDS" "BhavCopy_NSE_CD_0_0_0_*_F_0000.csv" "cur_bhavcopy.csv"

echo.
echo Process completed.

REM Open the margin calculator (keep margin_calc.html in the same DEST folder)
if exist "%DEST%\margin_calc.html" (
    start "" "%DEST%\margin_calc.html"
) else (
    echo margin_calc.html not found in %DEST%
    pause
)
exit /b


:CopyLatest
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$base = '%BASE%';" ^
 "$dest = '%DEST%';" ^
 "$folder = '%~1';" ^
 "$pattern = '%~2';" ^
 "$newname = '%~3';" ^
 "$year = '%YEAR%';" ^
 "$month = '%MONTHNAME%';" ^
 "$root = Join-Path (Join-Path (Join-Path $base $folder) $year) $month;" ^
 "if (-not (Test-Path -LiteralPath $root)) { Write-Host ('Folder not found: ' + $root) -ForegroundColor Red; exit 1 };" ^
 "$files = Get-ChildItem -LiteralPath $root -Directory | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -File -Filter $pattern -ErrorAction SilentlyContinue } | Where-Object { $_.Name -match '_\d{8}_F_0000\.csv$' } | Sort-Object { [long]([regex]::Match($_.Name, '_(\d{8})_F_0000\.csv$').Groups[1].Value) } -Descending;" ^
 "if (-not $files) { Write-Host ('File not found: ' + $pattern) -ForegroundColor Red; exit 2 };" ^
 "$latest = $files | Select-Object -First 1;" ^
 "Copy-Item -LiteralPath $latest.FullName -Destination (Join-Path $dest $newname) -Force;" ^
 "Write-Host ('Copied: ' + $latest.Name + ' as ' + $newname) -ForegroundColor Green"

exit /b

