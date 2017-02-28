[CmdletBinding()]
param(
	[string] $DestinationRepo,
	[string] $DestinationRepoUser,
	[string] $DestinationRepoPass,
	[string] $Branch,
    [string] $CommitMessage,
    [string] $Path
)


Trace-VstsEnteringInvocation $MyInvocation

$DestinationRepo = Get-VstsInput -Name DestinationRepo -Require 
$DestinationRepoUser = Get-VstsInput -Name DestinationRepoUser
$DestinationRepoPass = Get-VstsInput -Name DestinationRepoPass -Require 
$Branch = Get-VstsInput -Name Branch -Require
$CommitMessage = Get-VstsInput -Name CommitMessage -Require
$Path = Get-VstsInput -Name Path

cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
if($Path -ne "") {#
    $exists = Test-Path($Path)
    if($exists -eq $false) {
        throw ("Path specified is not a valid full or relative path. Drop location: $env:SYSTEM_DEFAULTWORKINGDIRECTORY Path: $Path");
    }
}

Write-Host "Commiting everything in the current location to $DestinationRepo"

### make working directory
mkdir "_gWork\"

### off to the folder
cd "_gWork\"

### git init
Write-VstsTaskVerbose ">>git init"
git init

if($LASTEXITCODE -ne 0) {
    throw ("Git init failed.");
}

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

### checkout existing
Write-VstsTaskVerbose ">>git pull destination $Branch"
git pull destination $Branch

if($LASTEXITCODE -ne 0) {
    throw ("Pull failed.");
}

if($Branch -ne "master") {
    git checkout $Branch
}

### copy from path into repo
$dest = ($env:SYSTEM_DEFAULTWORKINGDIRECTORY + "\_gWork")
cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
cd $Path
$src = (Get-Item -Path ".\" -Verbose).FullName

### avoid infinite recursion
$src = Get-ChildItem -Path $src -Exclude @("\_gWork","_gWork","\_gWork\","_gWork\")

    foreach($source in $src) {
        if($source.Attributes -eq "Directory") {
            Copy-Item -Path $source -Destination ($dest + "\" + $source.Name) -Recurse -Force
        } else {
            Copy-Item -Path $source -Destination $dest -Force 
        }
    }


cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
cd "_gWork"

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
Write-VstsTaskVerbose ">>git push --set-upstream destination $Branch"
git push --set-upstream destination $Branch

if($LASTEXITCODE -ne 0) {
    throw ("Push failed. If a proxy is configured, check that it has the credentials used for the push.");
}


### remove target
Write-VstsTaskVerbose ">>git remote remove target"
git remote remove destination

### remove local repo and return to the drop location
cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
Remove-Item "_gWork\" -Force -Recurse 
