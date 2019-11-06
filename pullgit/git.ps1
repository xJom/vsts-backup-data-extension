[CmdletBinding()]
param(
	[string] $SourceRepo,
	[string] $SourceRepoUser,
	[string] $SourceRepoPass,
	[string] $Path,
	[string] $Branch
)

$env:GIT_REDIRECT_STDERR = '2>&1'

Trace-VstsEnteringInvocation $MyInvocation

cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY

$SourceRepo = Get-VstsInput -Name SourceRepo -Require 
$SourceRepoUser = Get-VstsInput -Name SourceRepoUser
$SourceRepoPass = Get-VstsInput -Name SourceRepoPass 
$Path = Get-VstsInput -Name Path
$Branch = Get-VstsInput -Name Branch -Require

Write-VstsTaskDebug "Getting $SourceRepo and placing it in $Path" 
cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
if($Path -ne "") {
    $exists = Test-Path($Path)
    if($exists -eq $false) {
	
		try {
			New-Item $Path -ItemType Directory
		} catch {
			throw ("The drop path specified is either not a valid full or relative path, or the task execution context did not have sufficient permissions to create the path. Drop location: $env:SYSTEM_DEFAULTWORKINGDIRECTORY Path: $Path");
		}
        
    }
}

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
if(($SourceRepoUser -eq "") -and ($SourceRepoPass -eq "")) {
    
    # no credentials - just URI
    $source = $SourceRepo

} elseif($SourceRepoUser -eq "") {
    
    # no user name - just PAT or password
    $source = $SourceRepo.Replace("//", "//" + $SourceRepoPass + "@")

} else {

    # traditional credentials 
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

### copy from working directory
Write-VstsTaskVerbose ">> copying files from _gWork to destination"

### copy from path into repo
cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
cd $Path
$dest = (Get-Item -Path ".\" -Verbose).FullName
cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
cd "_gWork"
Remove-Item ".git\" -Force -Recurse
$src = (Get-Item -Path ".\" -Verbose).FullName
$src = $src + "\*"
cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
Copy-Item -Path $src -Destination $dest -Recurse -Force

### remove local repo and return to the drop location
cd $env:SYSTEM_DEFAULTWORKINGDIRECTORY
Remove-Item "_gWork\" -Force -Recurse 
