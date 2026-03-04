param(
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [switch]$Clean,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Name"
    & $Action
}

function Invoke-ConfigureWithRetry {
    param(
        [int]$MaxAttempts = 3
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-Host ""
        Write-Host "CMake configure attempt $attempt of $MaxAttempts"
        cmake --preset windows-vs2022

        if ($LASTEXITCODE -eq 0) {
            return
        }

        if ($attempt -eq $MaxAttempts) {
            throw "CMake configure failed after $MaxAttempts attempts."
        }

        Write-Host "Configure failed; removing build/windows-vs2022 before retry..."
        if (Test-Path "build/windows-vs2022") {
            Remove-Item -Path "build/windows-vs2022" -Recurse -Force
        }

        Start-Sleep -Seconds (15 * $attempt)
    }
}

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "CMake was not found in PATH. Install CMake 3.21+ and try again."
}

if ($Clean -and (Test-Path "build/windows-vs2022")) {
    Invoke-Step -Name "Cleaning previous Windows build directory" -Action {
        Remove-Item -Path "build/windows-vs2022" -Recurse -Force
    }
}

Invoke-Step -Name "Configuring project" -Action {
    Invoke-ConfigureWithRetry -MaxAttempts 3
}

Invoke-Step -Name "Building app and tests ($Configuration)" -Action {
    cmake --build --preset windows-vs2022-release --config $Configuration
}

if (-not $SkipTests) {
    Invoke-Step -Name "Running UI regression tests ($Configuration)" -Action {
        ctest --preset windows-vs2022-release-tests --output-on-failure -C $Configuration
    }
}

$exe = Get-ChildItem -Path "build/windows-vs2022" -Filter "TheSampledexWorkflow.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

Write-Host ""
if ($null -ne $exe) {
    Write-Host "Build finished. Executable:" -ForegroundColor Green
    Write-Host $exe.FullName
} else {
    Write-Host "Build finished, but TheSampledexWorkflow.exe was not found under build/windows-vs2022." -ForegroundColor Yellow
}
