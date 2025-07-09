@echo off
echo Starting Windows configuration...

REM Create the PowerShell script
echo Write-Output "Starting manual Windows configuration..." > C:\setup.ps1
echo try { >> C:\setup.ps1
echo   $Password = ConvertTo-SecureString "${admin_password}" -AsPlainText -Force >> C:\setup.ps1
echo   New-LocalUser -Name "${user_name}" -Password $Password -FullName "${user_name}" -Description "RDP User" >> C:\setup.ps1
echo   Add-LocalGroupMember -Group "Administrators" -Member "${user_name}" >> C:\setup.ps1
echo   Add-LocalGroupMember -Group "Remote Desktop Users" -Member "${user_name}" >> C:\setup.ps1
echo   Write-Output "User ${user_name} created successfully" >> C:\setup.ps1
echo } catch { >> C:\setup.ps1
echo   Write-Output "Error creating user: $_" >> C:\setup.ps1
echo } >> C:\setup.ps1

REM Add RDP configuration to PowerShell script
echo Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0 >> C:\setup.ps1
echo Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -value 0 >> C:\setup.ps1
echo Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "SecurityLayer" -value 0 >> C:\setup.ps1
echo Enable-NetFirewallRule -DisplayGroup "Remote Desktop" >> C:\setup.ps1

REM Add additional security configurations
echo net user administrator /active:yes >> C:\setup.ps1
echo net user administrator "${admin_password}" >> C:\setup.ps1

REM Add service restart and verification
echo Restart-Service TermService -Force >> C:\setup.ps1
echo Start-Sleep -Seconds 10 >> C:\setup.ps1
echo Write-Output "RDP configuration completed" >> C:\setup.ps1

REM Enable OpenSSH Server
echo # Enable OpenSSH Server >> C:\setup.ps1
echo try { >> C:\setup.ps1
echo   Write-Output "Enabling OpenSSH Server..." >> C:\setup.ps1
echo   Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 >> C:\setup.ps1
echo   Start-Service sshd >> C:\setup.ps1
echo   Set-Service -Name sshd -StartupType 'Automatic' >> C:\setup.ps1
echo   Write-Output "OpenSSH Server enabled and started" >> C:\setup.ps1
echo } catch { >> C:\setup.ps1
echo   Write-Output "Error enabling OpenSSH Server: $_" >> C:\setup.ps1
echo } >> C:\setup.ps1

REM Set timezone to Paris, France
echo # Set timezone to Paris, France >> C:\setup.ps1
echo try { >> C:\setup.ps1
echo   Write-Output "Setting timezone to Paris, France..." >> C:\setup.ps1
echo   Set-TimeZone -Id "Romance Standard Time" >> C:\setup.ps1
echo   Write-Output "Timezone set to Paris, France successfully" >> C:\setup.ps1
echo } catch { >> C:\setup.ps1
echo   Write-Output "Error setting timezone: $_" >> C:\setup.ps1
echo } >> C:\setup.ps1

REM Add cloudflared installation
echo # Install cloudflared >> C:\setup.ps1
echo try { >> C:\setup.ps1
echo   Write-Output "Installing cloudflared..." >> C:\setup.ps1
echo   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 >> C:\setup.ps1
echo   $url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.msi" >> C:\setup.ps1
echo   $output = "C:\cloudflared-windows-amd64.msi" >> C:\setup.ps1
echo   $webClient = New-Object System.Net.WebClient >> C:\setup.ps1
echo   $webClient.Headers.Add("User-Agent", "PowerShell") >> C:\setup.ps1
echo   $webClient.DownloadFile($url, $output) >> C:\setup.ps1
echo   if (Test-Path $output) { >> C:\setup.ps1
echo     Start-Process msiexec.exe -Wait -ArgumentList "/I `"$output`" /quiet /norestart" >> C:\setup.ps1
echo     Write-Output "Cloudflared installed successfully" >> C:\setup.ps1
echo     # Add to PATH >> C:\setup.ps1
echo     $cloudflaredPaths = @("C:\Program Files\cloudflared", "C:\Program Files (x86)\cloudflared") >> C:\setup.ps1
echo     foreach ($path in $cloudflaredPaths) { >> C:\setup.ps1
echo       if (Test-Path "$path\cloudflared.exe") { >> C:\setup.ps1
echo         $env:PATH += ";$path" >> C:\setup.ps1
echo         [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$path", [EnvironmentVariableTarget]::Machine) >> C:\setup.ps1
echo         Write-Output "Cloudflared added to PATH: $path" >> C:\setup.ps1
echo         $cloudflaredExe = "$path\cloudflared.exe" >> C:\setup.ps1
echo         break >> C:\setup.ps1
echo       } >> C:\setup.ps1
echo     } >> C:\setup.ps1
echo     Remove-Item $output -Force -ErrorAction SilentlyContinue >> C:\setup.ps1
echo   } else { >> C:\setup.ps1
echo     Write-Output "Failed to download cloudflared" >> C:\setup.ps1
echo   } >> C:\setup.ps1
echo } catch { >> C:\setup.ps1
echo   Write-Output "Error installing cloudflared: $_" >> C:\setup.ps1
echo } >> C:\setup.ps1

REM Add cloudflared tunnel service installation
echo # Install cloudflared as Windows service with tunnel token >> C:\setup.ps1
echo try { >> C:\setup.ps1
echo   if ($cloudflaredExe -and (Test-Path $cloudflaredExe)) { >> C:\setup.ps1
echo     Write-Output "Installing cloudflared tunnel service..." >> C:\setup.ps1
echo     $tunnelToken = "${tunnel_secret_windows_gcp}" >> C:\setup.ps1
echo     Write-Output "Tunnel token length: $($tunnelToken.Length) characters" >> C:\setup.ps1
echo     # Check if tunnel token is provided and valid >> C:\setup.ps1
echo     if ($tunnelToken.Length -gt 50 -and $tunnelToken -notlike '*tunnel_secret_windows_gcp*') { >> C:\setup.ps1
echo       Write-Output "Valid tunnel token detected, installing service..." >> C:\setup.ps1
echo       # Install cloudflared service with tunnel token >> C:\setup.ps1
echo       $serviceArgs = "service", "install", $tunnelToken >> C:\setup.ps1
echo       $installProcess = Start-Process -FilePath $cloudflaredExe -ArgumentList $serviceArgs -Wait -PassThru -NoNewWindow >> C:\setup.ps1
echo       if ($installProcess.ExitCode -eq 0) { >> C:\setup.ps1
echo         Write-Output "Cloudflared service installed successfully with tunnel token" >> C:\setup.ps1
echo         # Wait a moment before starting >> C:\setup.ps1
echo         Start-Sleep -Seconds 5 >> C:\setup.ps1
echo         # Start the cloudflared service >> C:\setup.ps1
echo         Start-Service cloudflared -ErrorAction SilentlyContinue >> C:\setup.ps1
echo         Start-Sleep -Seconds 10 >> C:\setup.ps1
echo         $serviceStatus = Get-Service cloudflared -ErrorAction SilentlyContinue >> C:\setup.ps1
echo         if ($serviceStatus -and $serviceStatus.Status -eq 'Running') { >> C:\setup.ps1
echo           Write-Output "SUCCESS: Cloudflared service is running successfully" >> C:\setup.ps1
echo         } else { >> C:\setup.ps1
echo           Write-Output "Warning: Cloudflared service may not be running properly" >> C:\setup.ps1
echo           Write-Output "Service status: $($serviceStatus.Status)" >> C:\setup.ps1
echo         } >> C:\setup.ps1
echo       } else { >> C:\setup.ps1
echo         Write-Output "Failed to install cloudflared service. Exit code: $($installProcess.ExitCode)" >> C:\setup.ps1
echo       } >> C:\setup.ps1
echo     } else { >> C:\setup.ps1
echo       Write-Output "Invalid or missing tunnel token (length: $($tunnelToken.Length))" >> C:\setup.ps1
echo       Write-Output "Token preview: $($tunnelToken.Substring(0, [Math]::Min(50, $tunnelToken.Length)))" >> C:\setup.ps1
echo     } >> C:\setup.ps1
echo   } else { >> C:\setup.ps1
echo     Write-Output "Cloudflared executable not found, cannot install service" >> C:\setup.ps1
echo   } >> C:\setup.ps1
echo } catch { >> C:\setup.ps1
echo   Write-Output "Error installing cloudflared service: $_" >> C:\setup.ps1
echo } >> C:\setup.ps1

REM Add Datadog Agent installation
echo # Install Datadog Agent >> C:\setup.ps1
echo try { >> C:\setup.ps1
echo   Write-Output "Installing Datadog Agent..." >> C:\setup.ps1
echo   $env:DD_API_KEY = "${datadog_api_key}" >> C:\setup.ps1
echo   $env:DD_SITE = "${datadog_region}" >> C:\setup.ps1
echo   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 >> C:\setup.ps1
echo   $url = "https://s3.amazonaws.com/ddagent-windows-stable/datadog-agent-7-latest.amd64.msi" >> C:\setup.ps1
echo   $output = "C:\datadog-agent-7-latest.amd64.msi" >> C:\setup.ps1
echo   $webClient = New-Object System.Net.WebClient >> C:\setup.ps1
echo   $webClient.Headers.Add("User-Agent", "PowerShell") >> C:\setup.ps1
echo   $webClient.DownloadFile($url, $output) >> C:\setup.ps1
echo   if (Test-Path $output) { >> C:\setup.ps1
echo     Write-Output "Downloaded Datadog Agent installer" >> C:\setup.ps1
echo     # Install Datadog Agent >> C:\setup.ps1
echo     Start-Process msiexec.exe -Wait -ArgumentList "/I `"$output`" /quiet /norestart APIKEY=`"$env:DD_API_KEY`" SITE=`"$env:DD_SITE`" TAGS=`"environment:zero-trust-demo,cloud:gcp,role:windows_rdp,managed-by:terraform`"" >> C:\setup.ps1
echo     Write-Output "Datadog Agent installed successfully" >> C:\setup.ps1
echo     # Configure Datadog Agent >> C:\setup.ps1
echo     $configPath = "C:\ProgramData\Datadog\datadog.yaml" >> C:\setup.ps1
echo     if (Test-Path $configPath) { >> C:\setup.ps1
echo       # Add NPM configuration >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "`n# Network Performance Monitoring enabled" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "network:" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "  enabled: true" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "`nsystem_probe:" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "  enabled: true" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "  network:" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "    enabled: true" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "  runtime_security:" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "    enabled: false" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "  service_monitoring:" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "    enabled: true" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "`nprocess:" >> C:\setup.ps1
echo       Add-Content -Path $configPath -Value "  enabled: true" >> C:\setup.ps1
echo       Write-Output "Datadog Agent configuration updated" >> C:\setup.ps1
echo     } >> C:\setup.ps1
echo     # Start Datadog Agent service >> C:\setup.ps1
echo     Start-Sleep -Seconds 10 >> C:\setup.ps1
echo     Start-Service datadogagent -ErrorAction SilentlyContinue >> C:\setup.ps1
echo     Start-Sleep -Seconds 10 >> C:\setup.ps1
echo     $ddServiceStatus = Get-Service datadogagent -ErrorAction SilentlyContinue >> C:\setup.ps1
echo     if ($ddServiceStatus -and $ddServiceStatus.Status -eq 'Running') { >> C:\setup.ps1
echo       Write-Output "SUCCESS: Datadog Agent service is running successfully" >> C:\setup.ps1
echo     } else { >> C:\setup.ps1
echo       Write-Output "Warning: Datadog Agent service may not be running properly" >> C:\setup.ps1
echo       Write-Output "Service status: $($ddServiceStatus.Status)" >> C:\setup.ps1
echo     } >> C:\setup.ps1
echo     Remove-Item $output -Force -ErrorAction SilentlyContinue >> C:\setup.ps1
echo   } else { >> C:\setup.ps1
echo     Write-Output "Failed to download Datadog Agent" >> C:\setup.ps1
echo   } >> C:\setup.ps1
echo } catch { >> C:\setup.ps1
echo   Write-Output "Error installing Datadog Agent: $_" >> C:\setup.ps1
echo } >> C:\setup.ps1

REM Add logging with user info
echo Add-Content -Path "C:\Windows\Temp\cmd-setup.log" -Value "$(Get-Date) - Setup completed successfully for user ${user_name}" >> C:\setup.ps1

REM Execute the PowerShell script
echo Executing PowerShell configuration script...
powershell.exe -ExecutionPolicy Bypass -File C:\setup.ps1 > C:\setup.log 2>&1

REM Create a scheduled task to run on next boot as backup
echo Creating backup scheduled task...
schtasks /create /tn "SetupRDP" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\setup.ps1" /sc onstart /ru SYSTEM /f

REM Enable RDP via registry directly as backup
echo Enabling RDP via registry...
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f

REM Enable RDP firewall rule via netsh as backup
echo Enabling RDP firewall rule...
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes

echo Configuration script completed
echo Check C:\setup.log for PowerShell execution details
echo Check C:\Windows\Temp\cmd-setup.log for additional logs
