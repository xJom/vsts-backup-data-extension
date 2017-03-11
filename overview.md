# Backup Data Extension
This extension contains a variety of build tasks that help you extract data from VSTS (or other source control services) during a build and/or release.

## Tasks currently available

- Pull Git Repo
  - pulls any git repo during build into a folder or into the working directory
- Commit to Git
  - pushes a sub folder or everything in the working directory into a specified git repo
- Export Release Definitions
  - exports all (or a subset of all) release definitions from a specified VSTS account 
  - definitions can be downloaded into a sub folder or the current working directory

#### All tasks work during build and release 
#### All tasks work on Windows-build agents only
An update with cross-platform support is planned 

## Use cases

- You can use the git pull task to get everything in a Git repo, then use Git push to make a copy of this repo in a different location. 
- You can download the definition for your VSTS release whenever you release and upload it into your on-premises TFS.

## Code

Available on GitHub

## Parameters and Settings


#### Pull Git Repo

- Source Repo URI
- Username 
  - if required
- Password 
  - if required (also supports PAT)
- Source Branch 
- Drop dir

#### Commit to Git

- Destination Repo URI
- Username 
  - if required
- Password 
  - if required (also supports PAT)
- Destination Branch
- Git user name and e-mail 
- Commit Message 
- Target path

#### Export Release Definitions

- API endpoint URI
- Username 
  - if targeting TFS 2015
- Password or PAT 
  - if targeting TFS 2017 or VSTS
- Filter
  - simple "Contains" filter to narrow the amoutn of definitions downloaded
- Drop dir
- Drop dir
