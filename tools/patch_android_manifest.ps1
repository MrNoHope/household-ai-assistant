$root = Split-Path -Parent $PSScriptRoot
$manifest = Join-Path $root 'android\app\src\main\AndroidManifest.xml'
if (!(Test-Path $manifest)) {
    Write-Host 'Khong tim thay AndroidManifest.xml'
    exit 1
}
$content = Get-Content $manifest -Raw
$marker = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
$marker = $marker.Replace('\"','"')
$permissions = @'
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />

    <queries>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
    </queries>

'@
$permissions = $permissions.Replace('\"','"')
if ($content -notmatch 'android.permission.CAMERA') {
    if ($content.Contains($marker)) {
        $content = $content.Replace($marker, "$marker`r`n$permissions")
    } else {
        $content = $content.Replace('    <application', "$permissions    <application")
    }
}
Set-Content -Path $manifest -Value $content -Encoding UTF8
Write-Host 'Da patch AndroidManifest.xml'
