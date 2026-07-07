@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Khong tim thay lenh flutter. Hay cai Flutter SDK va mo lai Android Studio/Terminal.
  pause
  exit /b 1
)

if not exist pubspec.yaml (
  echo Khong thay pubspec.yaml. Hay chay file nay trong thu muc goc cua project.
  pause
  exit /b 1
)

if exist __ai_source_backup rmdir /s /q __ai_source_backup
mkdir __ai_source_backup
xcopy /e /i /y lib __ai_source_backup\lib >nul
copy /y pubspec.yaml __ai_source_backup\pubspec.yaml >nul
copy /y analysis_options.yaml __ai_source_backup\analysis_options.yaml >nul

echo Dang tao Android scaffold bang Flutter SDK tren may ban...
flutter create --platforms=android --project-name ai_household_app .
if errorlevel 1 (
  echo flutter create bi loi.
  pause
  exit /b 1
)

xcopy /e /i /y __ai_source_backup\lib lib >nul
copy /y __ai_source_backup\pubspec.yaml pubspec.yaml >nul
copy /y __ai_source_backup\analysis_options.yaml analysis_options.yaml >nul

echo Dang them quyen camera, internet va TTS vao AndroidManifest...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\patch_android_manifest.ps1
if errorlevel 1 (
  echo Patch AndroidManifest bi loi. Ban co the them quyen thu cong theo README.
  pause
  exit /b 1
)

echo Dang tai package Flutter...
flutter pub get
if errorlevel 1 (
  echo flutter pub get bi loi.
  pause
  exit /b 1
)

echo.
echo XONG. Bay gio mo thu muc nay bang Android Studio, chon dien thoai Android va bam Run.
echo Hoac chay: flutter run
pause
