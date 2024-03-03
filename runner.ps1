$experiment_folder = '.\test'
$conference_tool_paths = '.\conftool_paths.txt'


function GetConfToolVersion([string]$confTool) {
    $line = (Get-Content $conference_tool_paths | Select-String -Pattern $confTool)
    $path = $line -split ', ' | Select-Object -Last 1
    return (Get-Item -LiteralPath $path).VersionInfo | Format-List * -force
    # return $version
}

# Get Zoom version  
Write-Output $(GetConfToolVersion 'Zoom') > $experiment_folder\zoom_version.txt

# Get Teams version
Write-Output $(GetConfToolVersion 'Teams') > $experiment_folder\teams_version.txt

