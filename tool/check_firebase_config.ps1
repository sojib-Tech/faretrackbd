# Firebase Configuration Diagnostic Script
# Run: powershell -File tool/check_firebase_config.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
function Join {
    param([string]$a, [string]$b, [string]$c, [string]$d)
    $r = $a; if ($b) { $r = [System.IO.Path]::Combine($r, $b) }
    if ($c) { $r = [System.IO.Path]::Combine($r, $c) }
    if ($d) { $r = [System.IO.Path]::Combine($r, $d) }
    return $r
}
$passed = 0
$failed = 0

function Check {
    param($Label, $Condition, $Hint)
    if (& $Condition) {
        Write-Host "  [PASS] $Label" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $Label" -ForegroundColor Red
        Write-Host "         $Hint" -ForegroundColor Yellow
        $script:failed++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Firebase Config Diagnostic" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ---- 1. google-services.json ----
Write-Host '[Android] google-services.json' -ForegroundColor Magenta
$gsPath = Join $root "android" "app" "google-services.json"
$gsValid = $false
if (Test-Path $gsPath) {
    try {
        $gs = Get-Content $gsPath -Raw | ConvertFrom-Json
        $gsValid = $true
    } catch { $gsValid = $false }
}
Check 'File exists at android/app/google-services.json' { Test-Path $gsPath } 'Place google-services.json in android/app/'
Check 'Valid JSON content' { $gsValid } 'The file is malformed or empty'

if ($gsValid) {
    $pkg = $gs.client[0].client_info.android_client_info.package_name
    $projId = $gs.project_info.project_id
    $apiKey = $gs.client[0].api_key[0].current_key

    $gradle = Get-Content (Join $root "android" "app" "build.gradle.kts") -Raw
    $null = $gradle -match 'namespace\s*=\s*"([^"]+)"'
    $ns = $matches[1]

    Check 'Package name matches build.gradle.kts' { $pkg -eq $ns } "google-services.json has '$pkg', build.gradle.kts has '$ns'"
    Check "Project ID is 'faretrackbd'" { $projId -eq "faretrackbd" } "Found '$projId' - may be wrong Firebase project"
    Check 'API key is non-empty' { $apiKey -and $apiKey.Length -gt 10 } 'API key is missing or too short'
}

# ---- 2. firebase_options.dart ----
Write-Host "`n[Dart] firebase_options.dart" -ForegroundColor Magenta
$fboPath = Join $root "lib" "firebase_options.dart"
Check 'File exists at lib/firebase_options.dart' { Test-Path $fboPath } 'Run: flutterfire configure --project=faretrackbd'
if (Test-Path $fboPath) {
    $fbo = Get-Content $fboPath -Raw
    $hasAndroid = $fbo -match "static const FirebaseOptions android"
    $hasiOS = $fbo -match "static const FirebaseOptions ios"
    Check 'Android options defined' { $hasAndroid } 'Missing android config in firebase_options.dart'
    Check 'iOS options defined' { $hasiOS } 'Missing ios config in firebase_options.dart'
}

# ---- 3. iOS plist ----
Write-Host "`n[iOS] GoogleService-Info.plist" -ForegroundColor Magenta
$plistPath = Join $root "ios" "Runner" "GoogleService-Info.plist"
$plistExists = Test-Path $plistPath
Check 'File exists at ios/Runner/GoogleService-Info.plist' { $plistExists } 'Optional with firebase_options.dart, recommended for Crashlytics/Dynamic Links'

# ---- 4. main.dart init order ----
Write-Host "`n[Dart] main.dart initialization order" -ForegroundColor Magenta
$main = Get-Content (Join $root "lib" "main.dart") -Raw
Check 'WidgetsFlutterBinding.ensureInitialized called' { $main -match "WidgetsFlutterBinding.ensureInitialized" } 'Add WidgetsFlutterBinding.ensureInitialized before Firebase.initializeApp'
Check 'Firebase.initializeApp called after ensureInitialized' { $main -match "WidgetsFlutterBinding.ensureInitialized[\s\S]*Firebase.initializeApp" } 'Call WidgetsFlutterBinding.ensureInitialized BEFORE Firebase.initializeApp'
Check 'Firebase init is awaited' { $main -match "await Firebase\.initializeApp" } "Missing 'await' before Firebase.initializeApp"
Check 'Firebase init uses DefaultFirebaseOptions' { $main -match "DefaultFirebaseOptions.currentPlatform" } 'Pass options: DefaultFirebaseOptions.currentPlatform'

# ---- Summary ----
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================`n" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host 'Fix the [FAIL] items above, then run: flutterfire configure --project=faretrackbd' -ForegroundColor Yellow
    exit 1
} else {
    Write-Host 'All checks passed. Firebase config looks correct.' -ForegroundColor Green
}
