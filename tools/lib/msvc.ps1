# lib/msvc.ps1 - where the MSVC toolset and Windows SDK are on THIS machine, for the
# host test runner (tools/host-test.ps1). Dot-source it and call Enter-BvrMsvcEnv.
#
# vswhere first (it finds the VS Build Tools under Program Files (x86) as well as a
# full Visual Studio), a glob as the fallback, and a clear error naming both. Ported
# from the Dishonored VR mod, where a hardcoded glob made every host suite throw on a
# Build-Tools-only machine.
# NOTE: keep this file pure ASCII (PowerShell 5.1 misreads BOM-less UTF-8).
function Get-BvrMsvcRoot {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $root = $null
    if (Test-Path $vswhere) {
        $vs = & $vswhere -latest -products * -property installationPath | Select-Object -First 1
        if ($vs) {
            $root = (Get-ChildItem "$vs\VC\Tools\MSVC\*" -Directory -ErrorAction SilentlyContinue |
                     Sort-Object Name -Descending | Select-Object -First 1).FullName
        }
    }
    if (-not $root) {
        $root = (Get-ChildItem "C:\Program Files\Microsoft Visual Studio\*\*\VC\Tools\MSVC\*" -Directory -ErrorAction SilentlyContinue |
                 Sort-Object Name -Descending | Select-Object -First 1).FullName
    }
    if (-not $root) {
        throw "MSVC toolset not found: neither vswhere ($vswhere) nor C:\Program Files\Microsoft Visual Studio\*\*\VC\Tools\MSVC has one. Install the VS Build Tools C++ workload."
    }
    return $root
}

# The newest Windows SDK that is really installed: its Include\<v>\um\windows.h and its
# Lib\<v>\um both exist. Sorting the folder names alone is not enough - a WDK adds a
# "wdf" folder that sorts above every "10.0.x" (found on the GitHub Windows runner).
function Get-BvrWinSdk {
    $kits = "${env:ProgramFiles(x86)}\Windows Kits\10"
    $v = Get-ChildItem "$kits\Include" -Directory -ErrorAction SilentlyContinue |
         Where-Object { $_.Name -match '^\d+(\.\d+){3}$' -and
                        (Test-Path "$($_.FullName)\um\windows.h") -and
                        (Test-Path "$kits\Lib\$($_.Name)\um") } |
         Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
    if (-not $v) { throw "Windows 10/11 SDK not found under $kits (no version with um\windows.h)" }
    return [pscustomobject]@{ Include = $v.FullName; Lib = "$kits\Lib\$($v.Name)" }
}

# Sets INCLUDE/LIB for a 32-bit host build and returns what to restore, plus cl.exe.
function Enter-BvrMsvcEnv {
    $root = Get-BvrMsvcRoot
    $win = Get-BvrWinSdk
    $sdk = $win.Include
    $lib = $win.Lib
    $saved = @{ INCLUDE = $env:INCLUDE; LIB = $env:LIB }
    $env:INCLUDE = "$root\include;$sdk\ucrt;$sdk\shared;$sdk\um"
    $env:LIB = "$root\lib\x86;$lib\ucrt\x86;$lib\um\x86"
    return [pscustomobject]@{ Cl = "$root\bin\Hostx64\x86\cl.exe"; Saved = $saved }
}

function Exit-BvrMsvcEnv($State) {
    if (-not $State) { return }
    $env:INCLUDE = $State.Saved.INCLUDE
    $env:LIB = $State.Saved.LIB
}
