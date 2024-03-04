$conference_tool_paths = '.\conftool_paths.secret'
$number_of_runs = 1
$experiment_length = 60 # in seconds
$cooldown_length = 30 # in seconds
$variation = 'default'
$sample_interval = 1 # in seconds

function GetConfToolPath([string]$conf_tool) {
    $line = (Get-Content $conference_tool_paths | Select-String -Pattern $conf_tool)
    $path = ($line -split ', ')[1]
    return $path
}
function GetConfToolLink([string]$conf_tool) {
  $line = (Get-Content $conference_tool_paths | Select-String -Pattern $conf_tool)
  $link = ($line -split ', ')[2]
  return $link
}

try {
  $experiment_folder = '.\experiments\'
  New-Item $experiment_folder -ItemType Directory -Force | Out-Null

  # echo $experiment_length

  # PCM Sanity check
  pcm $sample_interval -i=60 -csv=".\experiments\pcm_sanity.log"

  # pcm running idle
  pcm $sample_interval -i=60 -csv=".\experiments\pcm_idle.log"

  for ($i = 0; $i -lt $number_of_runs; $i++) {
    foreach ($tool in @('Zoom', 'Teams')) {
      # Create a folder for the experiment
      $experiment_folder = '.\experiments\' + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + '_' + $tool + "_" + $variation
      New-Item $experiment_folder -ItemType Directory -Force | Out-Null

      # Open link from shell https://debug.to/696/open-url-in-browser-in-powershell
      $link = (GetConfToolLink $tool)
      Start-Process "$link"
      
      Write-Output "Experiment $i $tool started"

      # Wait for the conference tool to start
      Start-Sleep -Seconds 20

      if ($tool -eq 'Teams') {
        python .\teams_join.py
      }

      # Start Intel PCM
      pcm $sample_interval -i=60 -csv="$experiment_folder\pcm.log"
      
      # # Start the experiment
      # Start-Sleep -Seconds ($experiment_length * 60)

      # # Stop Intel PCM
      # Stop-Job $pcm_job
      
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
  # Close pcm
  Stop-Job $pcm_job

  # Close the conference tool
  $path = GetConfToolPath 'Zoom'
  $exe = $path -split '\\' | Select-Object -Last 1
  taskkill /F /T /IM $exe
  $path = GetConfToolPath 'Teams'
  $exe = $path -split '\\' | Select-Object -Last 1
  taskkill /F /T /IM $exe
  Write-Output "Experiment ended"
}

