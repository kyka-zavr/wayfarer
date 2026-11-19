#requires -Version 5.1
<#
.SYNOPSIS
    Builds Wayfarer (Rust core + Qt shell) from a plain PowerShell window.

.DESCRIPTION
    Ninja cannot find MSVC on its own, so this imports the environment that
    vcvars64.bat would set, then configures and builds. vswhere is used instead
    of a hardcoded path because the install directory differs between VS 2022
    (VS\2022) and VS 2026 (VS\18).

.EXAMPLE
    .\scripts\build.ps1
    .\scripts\build.ps1 -Config Debug
    .\scripts\build.ps1 -QtPath C:/Qt/6.9.3/msvc2022_64
#>
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Config = 'Release',

    [string]$QtPath = 'C:/Qt/6.8.3/msvc2022_64',

    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build'

if (-not (Test-Path (Join-Path $QtPath 'lib/cmake/Qt6'))) {
    throw "Qt 6 not found at '$QtPath'. Pass -QtPath, e.g. -QtPath C:/Qt/6.8.3/msvc2022_64"
}

# --- locate MSVC -----------------------------------------------------------
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) {
    throw 'vswhere.exe not found. Install "Visual Studio Build Tools" with the C++ workload.'
}

$vsPath = & $vswhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath

if (-not $vsPath) {
    throw 'No MSVC toolset found. Add the "Desktop development with C++" workload to Build Tools.'
}

$vcvars = Join-Path $vsPath 'VC\Auxiliary\Build\vcvars64.bat'

# vcvars writes to stderr on success too, so do not let PowerShell treat it as an error.
$envDump = cmd /c "`"$vcvars`" >nul 2>&1 && set"
foreach ($line in $envDump) {
    if ($line -match '^([^=]+)=(.*)$') {
        Set-Item -Path "env:$($matches[1])" -Value $matches[2]
    }
}

# cargo is installed per-user and is usually not on PATH in a fresh shell.
$cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'
if (Test-Path $cargoBin) { $env:Path = "$cargoBin;$env:Path" }

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw 'cargo not found. Install Rust: winget install --exact --id Rustlang.Rustup'
}

# --- build -----------------------------------------------------------------
if ($Clean -and (Test-Path $buildDir)) {
    Write-Host "cleaning $buildDir" -ForegroundColor DarkGray
    Remove-Item $buildDir -Recurse -Force
}

Write-Host "MSVC      : $vsPath" -ForegroundColor DarkGray
Write-Host "Qt        : $QtPath" -ForegroundColor DarkGray
Write-Host "Config    : $Config" -ForegroundColor DarkGray

cmake -S (Join-Path $root 'shell') -B $buildDir -G Ninja `
    "-DCMAKE_BUILD_TYPE=$Config" `
    "-DCMAKE_PREFIX_PATH=$QtPath"
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed ($LASTEXITCODE)" }

cmake --build $buildDir
if ($LASTEXITCODE -ne 0) { throw "cmake build failed ($LASTEXITCODE)" }

Write-Host "`nOK -> $buildDir\wayfarer-shell.exe" -ForegroundColor Green
