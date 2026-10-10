$ErrorActionPreference = "Stop"

# 1. Read pubspec.yaml
$pubspecPath = "pubspec.yaml"
$pubspec = Get-Content $pubspecPath

# 2. Find and increment version
$newVersion = ""
$newPubspec = foreach ($line in $pubspec) {
    if ($line -match "^version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
        $baseVersion = $matches[1]
        $buildNumber = [int]$matches[2]
        $newBuildNumber = $buildNumber + 1
        $newVersion = "$baseVersion+$newBuildNumber"
        "version: $newVersion"
    } else {
        $line
    }
}

if ($newVersion -eq "") {
    Write-Host "Could not find version in pubspec.yaml" -ForegroundColor Red
    exit 1
}

# 3. Write back to pubspec.yaml
$newPubspec | Set-Content $pubspecPath
Write-Host "Updated pubspec.yaml to version $newVersion" -ForegroundColor Green

# 4. Run flutter build apk
Write-Host "Building APK..." -ForegroundColor Cyan
flutter build apk

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 5. Copy and rename APK
$sourceApk = "build/app/outputs/flutter-apk/app-release.apk"
$destDir = "build/app/outputs/flutter-apk/"
$destApkName = "phiendich_v${newVersion}.apk"
$destApk = Join-Path $destDir $destApkName

Copy-Item $sourceApk -Destination $destApk -Force
Write-Host "Successfully built and copied APK to $destApk" -ForegroundColor Green
