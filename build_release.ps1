# Builds the Play Store bundle (build/app/outputs/bundle/release/app-release.aab).
#
#   .\build_release.ps1 -ApiUrl https://api.example.lk
#
# Needs android/key.properties + android/upload-keystore.jks (see README).
param(
    [Parameter(Mandatory = $true)][string]$ApiUrl
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if ($ApiUrl -notmatch '^https://') { throw "ApiUrl must be https:// (got '$ApiUrl')." }
if (-not (Test-Path android/key.properties)) { throw 'android/key.properties is missing: release would be debug-signed and Play rejects it.' }

flutter build appbundle --release "--dart-define=API_BASE_URL=$($ApiUrl.TrimEnd('/'))"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "`nUpload: build/app/outputs/bundle/release/app-release.aab"
