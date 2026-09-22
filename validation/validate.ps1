# Run in the project root on your Windows Flutter machine.
$ErrorActionPreference = 'Stop'
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
dart format lib test
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter build apk --debug
exit $LASTEXITCODE
