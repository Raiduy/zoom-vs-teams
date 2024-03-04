$conference_tool_paths = '.\conftool_paths.secret'
$number_of_runs = 1
$experiment_length = 10 # in minutes
$cooldown_length = 5 # in minutes


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


for ($i = 0; $i -lt $number_of_runs; $i++) {
  foreach ($tool in @('Zoom', 'Teams')) {
    # Create a folder for the experiment
    $experiment_folder = '.\experiments\' + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + '_' + $tool
    New-Item $experiment_folder -ItemType Directory -Force | Out-Null

    # Open link from shell https://debug.to/696/open-url-in-browser-in-powershell
    $link = '"' + (GetConfToolLink $tool) + '"'
    Start-Process $link
    
    Write-Output "Experiment $i $tool started"

    # # Wait for the conference tool to start
    Start-Sleep -Seconds 15

    if ($tool -eq 'Teams') {
      python .\teams_join.py
    }

    
    # # Start the experiment
    # Start-Sleep -Seconds ($experiment_length * 60)
    
    # # Close the conference tool
    $path = GetConfToolPath $tool
    $exe = $path -split '\\' | Select-Object -Last 1
    taskkill /F /T /IM $exe
    
    
    # Get Tool version
    (Get-Item -LiteralPath $path).VersionInfo | Format-List * -force > $experiment_folder\version.log
    
    Write-Output "Experiment $i $tool ended"
    Start-Sleep -Seconds 5
  }
}

