param (
  [string]$conference_tool_paths = '.\conftool_paths.secret',
  [int]$number_of_runs = 2,
  [int]$experiment_length = 60, # in seconds
  [int]$cooldown_length = 30, # in seconds
  [string]$variation = 'default',
  [int]$sample_interval = 1 # in seconds,
)

function GetConfToolPath([string]$conf_tool) {
    $line = (Get-Content $conference_tool_paths | Select-String -Pattern $conf_tool)
    $path = ($line -split ', ')[1]
    return $path
}
function GetConfToolMeetingLink([string]$conf_tool) {
  $line = (Get-Content $conference_tool_paths | Select-String -Pattern $conf_tool)
  $link = ($line -split ', ')[2]
  return $link
}

$GetBatteryStatus = {
  param ([string]$folder)
    Write-Host "Starting battery status check..."
    $file_headers = "Timestamp, BatteryStatus, BatteryRemaining%, EstimatedRunTime"
    $file_headers | Out-File -FilePath $folder\battery.log 

    try {
      while ($True) {
        $current_time = Get-Date -Format "yyyy-MM-dd_HH-mm-ss.fff"
        $battery_status = (Get-WmiObject win32_battery).batteryStatus
        $battery_remaining = (Get-WmiObject win32_battery).estimatedChargeRemaining
        $estimated_run_time = (Get-WmiObject win32_battery).estimatedRunTime

        $line = "$current_time, $battery_status, $battery_remaining, $estimated_run_time"
        $line >> $folder\battery.log

        Start-Sleep -Seconds 1
      }
    } catch {
      Write-Host "Battery status check failed"
    }
}

$GetPCMStats = {
  param ([string]$folder)

    try {
      echo "Starting PCM collection..." >> $folder\pcm_debug.log
      pcm -r $sample_interval -csv="$folder\pcm.log" 2>&1 >> $folder\pcm_debug.log
      # pcm -h 2>&1 >> $folder\pcm_debug.log
    } catch {
      echo "PCM collection check failed" >> $folder\pcm_debug.log
    } finally {
      echo "PCM collection ended" >> $folder\pcm_debug.log
    }
}


try {
  $experiment_folder = '.\experiments\'
  New-Item $experiment_folder -ItemType Directory -Force | Out-Null

  # PCM Sanity check
  $PCMJob = Start-Job -ScriptBlock $GetPCMStats -ArgumentList $PSScriptRoot
  Start-Sleep -Seconds 10

  Stop-Job $PCMJob
  # Remove-Job $PCMJob

  Start-Sleep -Seconds 10

  # pcm $sample_interval -csv=".\experiments\pcm_sanity.log"

  # pcm running idle
  # pcm $sample_interval -i=60 -csv=".\experiments\pcm_idle.log"

  for ($i = 0; $i -lt $number_of_runs; $i++) {
    foreach ($tool in @('Zoom', 'Teams')) {
      # Create a folder for the experiment
      $experiment_folder = '.\experiments\' + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + '_' + $tool + "_" + $variation
      New-Item $experiment_folder -ItemType Directory -Force | Out-Null

      $experiment_full_path = (Get-Item -LiteralPath $experiment_folder).FullName
      Write-Output "Experiment folder: $experiment_full_path"
      
      # Open link from shell https://debug.to/696/open-url-in-browser-in-powershell
      $link = (GetConfToolMeetingLink $tool)
      Start-Process "$link"
      
      Write-Output "Experiment $i $tool started"
      
      # Wait for the conference tool to start
      Start-Sleep -Seconds 20
      
      if ($tool -eq 'Teams') {
        # Auto join the meeting in Teams
        python .\teams_autojoin.py
      }
      
      # Run Intel PCM for 60 iterations
      $BatteryJob = Start-Job -ScriptBlock $GetBatteryStatus -ArgumentList $experiment_full_path
      $PCMJob = Start-Job -ScriptBlock $GetPCMStats -ArgumentList $experiment_full_path
      
      Start-Sleep -Seconds $experiment_length

      # Stop PCM collection
      Stop-Job $PCMJob
      # Remove-Job $PCMJob

      # Stop battery status check
      Stop-Job $BatteryJob
      # Remove-Job $BatteryJob
      
      # # Close the conference tool
      $path = GetConfToolPath $tool
      $exe = $path -split '\\' | Select-Object -Last 1
      taskkill /F /T /IM $exe
      
      # Get Tool version
      (Get-Item -LiteralPath $path).VersionInfo | Format-List * -force > $experiment_folder\version.log
      
      Write-Output "Experiment $i $tool ended"
      Start-Sleep -Seconds $cooldown_length
    }
  }
} finally {
  # Stop PCM and battery status check
  Stop-Job $PCMJob
  Stop-Job $BatteryJob

  # Close the conference tool
  $path = GetConfToolPath 'Zoom'
  $exe = $path -split '\\' | Select-Object -Last 1
  taskkill /F /T /IM $exe
  $path = GetConfToolPath 'Teams'
  $exe = $path -split '\\' | Select-Object -Last 1
  taskkill /F /T /IM $exe
  Write-Output "Experiment ended"
}

