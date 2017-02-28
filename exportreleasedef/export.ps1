[CmdletBinding()]
param(
	[string] $Collection,
	[string] $UserName,
	[string] $Pass,
	[string] $FilterString,
    [string] $ReleaseDir
)

# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation

$WorkingDir = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
$ReleaseDir = Get-VstsInput -Name DropDir 

if(!$WorkingDir.EndsWith("\")) {
    $WorkingDir = $WorkingDir + "\"
}

if(!$ReleaseDir.EndsWith("\")) {
    $ReleaseDir = $ReleaseDir + "\"
}

while($ReleaseDir.StartsWith("\")) {
    $ReleaseDir = $ReleaseDir.Substring(1);
}

cd $WorkingDir

if(($ReleaseDir -eq "") -or ($ReleaseDir.Replace("\","").Equals(""))) {
    ### do not create a folder if we are downloading into the drop location
    $ReleaseDir = ""
} else {
    if(Test-Path($WorkingDir + $ReleaseDir)) {
        Remove-Item ($WorkingDir + $ReleaseDir) -Force -Recursive
    }

    mkdir $ReleaseDir
}

$Collection = Get-VstsInput -Name Collection -Require
$UserName = Get-VstsInput -Name UserName
$Pass = Get-VstsInput -Name Pass -Require
$FilterString = Get-VstsInput -Name FilterString

$ContentType = "application/json"

$wc = New-Object System.Net.WebClient 
$wc.Headers["Content-Type"] = $ContentType 

$pair = "${UserName}:${Pass}" 
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair) 
$base64 = [System.Convert]::ToBase64String($bytes) 
$wc.Headers.Add("Authorization","Basic $base64"); 

if(!$Collection.EndsWith("/")) {
   $Collection = $Collection + "/"
}

$uri = $Collection + "_apis/release/definitions?api-version=3.0-preview.1"

$jsondata = $wc.DownloadString($uri) | ConvertFrom-Json 

foreach($definition in $jsondata.value) {
	if($FilterString -ne "") {
		if(!$definition.name.Contains($FilterString)) {
			continue
		}
	}
	
    $npath = $WorkingDir + $ReleaseDir + $definition.name + ".json"
	Write-Host "Exporting " $definition.name "by downloading" $definition.url "to" $npath
	
	$wc.DownloadFile($definition.url, $npath)
}

Trace-VstsLeavingInvocation $MyInvocation