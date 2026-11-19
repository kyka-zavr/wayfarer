#requires -Version 5.1
<#
.SYNOPSIS
    Runs the freshly built Wayfarer shell.

.DESCRIPTION
    Qt DLLs are not copied into the build tree, so this puts Qt's bin directory
    on PATH first. Use scripts/package.ps1 (later) for a self-contained drop.
#>
param(
    [string]$QtPath = 'C:/Qt/6.8.3/msvc2022_64',
    [ValidateSet('Debug', 'Release')]
    [string]$Config = 'Release'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root "build/wayfarer-shell.exe"

if (-not (Test-Path $exe)) {
    throw "not built yet: $exe  (run .\scripts\build.ps1 first)"
}

$env:Path = "$QtPath/bin;$env:Path"
$env:QT_FORCE_STDERR_LOGGING = '1'   # keep QML warnings visible in this console

& $exe
