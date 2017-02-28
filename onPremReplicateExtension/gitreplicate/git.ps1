[CmdletBinding()]
param(
	[string] $SourceRepo,
	[string] $SourceRepoUser,
	[string] $SourceRepoPass,
	[string] $DestinationRepo,
	[string] $DestinationRepoUser,
	[string] $DestinationRepoPass,
	[string] $Branch,
    [string] $CommitMessage
)


Trace-VstsEnteringInvocation $MyInvocation

cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY

$SourceRepo = Get-VstsInput -Name SourceRepo -Require 
$SourceRepoUser = Get-VstsInput -Name SourceRepoUser
$SourceRepoPass = Get-VstsInput -Name SourceRepoPass -Require 
$DestinationRepo = Get-VstsInput -Name DestinationRepo -Require 
$DestinationRepoUser = Get-VstsInput -Name DestinationRepoUser
$DestinationRepoPass = Get-VstsInput -Name DestinationRepoPass -Require 
$Branch = Get-VstsInput -Name Branch -Require
$CommitMessage = Get-VstsInput -Name CommitMessage -Require

Write-VstsTaskDebug "Getting $SourceRepo and pushing it to $DestinationRepo" 

### make working directory
mkdir "_gWork"
cd "_gWork\"

### git init
Write-VstsTaskVerbose ">>git init"
git init

if($LASTEXITCODE -ne 0) {
    throw ("Git init failed.");
}

### add and pull target
Write-VstsTaskVerbose ">>git remote add source $SourceRepo"

$source = ""
if($SourceRepoUser -eq "") {
    $source = $SourceRepo.Replace("//", "//" + $SourceRepoPass + "@")
} else {
    $source = $SourceRepo.Replace("//", "//" + $SourceRepoUser + ":" + $SourceRepoPass + "@")
}

git remote add source $source

if($LASTEXITCODE -ne 0) {
    throw ("Could not configure source.");
}

### pull source
Write-VstsTaskVerbose ">>git pull source $Branch -f"
git pull source $Branch -f

if($LASTEXITCODE -ne 0) {
    throw ("There was an error trying to pull from the source on branch $Branch");
}

### remove source
Write-VstsTaskVerbose ">>git remote remove source"
git remote remove source

### add and commit to destination
Write-VstsTaskVerbose ">>git remote add destination $DestinationRepo"

$dest = ""
$destParts = $DestinationRepo.Split("//")
if($DestinationRepoUser -eq "") {
    $dest = $DestinationRepo.Replace("//", "//" + $DestinationRepoPass + "@")
} else {
    $dest = $DestinationRepo.Replace("//", "//" + $DestinationRepoUser + ":" + $DestinationRepoPass + "@")
}

git remote add destination $dest

if($LASTEXITCODE -ne 0) {
    throw ("Could not configure destination.");
}

git config --global user.name "VSO.Agent"

if($LASTEXITCODE -ne 0) {
    throw ("Could not configure name.");
}

### add files
Write-VstsTaskVerbose ">>git add ."
git add .

if($LASTEXITCODE -ne 0) {
    throw ("Add failed.");
}

### commit
Write-VstsTaskVerbose ">>git commit -m '$CommitMessage'"
git commit -m "$CommitMessage"

if($LASTEXITCODE -gt 1) {
    throw ("Commit failed. Terminating");
}

### push
Write-VstsTaskVerbose ">>git push --set-upstream destination master"
git push --set-upstream destination master

if($LASTEXITCODE -ne 0) {
    throw ("Push failed. If a proxy is configured, check that it has the credentials used for the push.");
}

### remove target
Write-VstsTaskVerbose ">>git remote remove target"
git remote remove destination

### clear directory
cd ".."
Remove-Item "_gWork\" -Force -Recurse
