#verify if its running as admin
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Warning "Run as administrator."
    exit
}

# file with all services
$file = "$PSScriptRoot\services.txt"

if (-not (Test-Path $file)) {
    Write-Error "File $file not found."
    exit
}

$lines = Get-Content -Path $file | Where-Object { $_ -match '\S' }

foreach ($line in $lines) {

    $parts = $line -split ','

    if ($parts.Count -lt 2) {
        Write-Output "Invalid line: $line"
        continue
    }

    $serviceName = $parts[0].Trim()
    $serviceState = $parts[1].Trim().ToLower()

    $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    $cim = Get-CimInstance Win32_Service -Filter "Name='$serviceName'" -ErrorAction SilentlyContinue

    if (-not $svc -or -not $cim) {
        Write-Output "Service not found: $serviceName"
        continue
    }

    $currentState = $cim.StartMode.ToLower()
    # verify if the process is alredy in the desired state
    if ($currentState -eq $serviceState) {
        Write-Output "Processing: $serviceName -> already $serviceState"
        continue
    }

    Write-Output "Processing: $serviceName ($currentState -> $serviceState)"

    try {
        if ($svc.Status -eq "Running") {
            try {
                Stop-Service -Name $serviceName -ErrorAction Stop
            }
            catch {
                Stop-Service -Name $serviceName -Force -ErrorAction Stop
            }
            Write-Output "  STOPPED"
        }
        if ($serviceState -notin @("manual", "disabled", "auto")) {
            Write-Output "INVALID STATE: $serviceName -> $serviceState"
            continue
        }
        switch ($serviceState) {
            "disabled" { Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop }
            "manual" { Set-Service -Name $serviceName -StartupType Manual -ErrorAction Stop }
            "auto" { Set-Service -Name $serviceName -StartupType Automatic -ErrorAction Stop }
        }

        Write-Output "  -> DONE"

    }
    catch {
        Write-Output "  -> SKIPPED ($($_.Exception.Message))"
    }
}
