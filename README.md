# fix-nextcloud-file-creation-date

### Contents
- [About](#About)
- [Fixing file creation dates](#Fixing)
- [Examples](#Examples)
- [Troubleshooting](#Troubleshooting)

### About
- fixes file creation date set back to 1970 by bugged version of nextcloud client
(see [Desktop client 3.4.0 destroys local time stamp and keeps uploading data to server](https://help.nextcloud.com/t/desktop-client-3-4-0-destroys-local-time-stamp-and-keeps-uploading-data-to-server))

- It is best to have a backup of nextcloud DB and data directory before running the script!

- This script overrides the file system file creation date of files in the nextcloud data directory with the date taken from nextcloud DB

- Uses SQL query by [wwe](https://help.nextcloud.com/u/wwe)
see [SQL query by wwe](https://help.nextcloud.com/t/desktop-client-3-4-0-destroys-local-time-stamp-and-keeps-uploading-data-to-server/128512/93)

- Tested on Ubuntu 20.04 LTS, MySQL DB, Nextcloud version Nextcloud Hub 3 (25.0.1)

- Requires [PowerShell](https://github.com/PowerShell/PowerShell) as well as the PS module [SimplySql](https://github.com/mithrandyr/SimplySql)


& './fix nextcloud file creation date.ps1'

### Fixing file creation dates

#### 1) Install PowerShell
  - Microsoft recommended way
    - download PowerShell
      ```
      wget https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell_7.3.0-1.deb_amd64.deb
      ```

    - Install the downloaded package
      ```
      sudo dpkg -i powershell_7.3.0-1.deb_amd64.deb
      ```
    - Resolve missing dependencies and finish the install (if necessary)
      ```
      sudo apt-get install -f
      ```
  - using Snap
  ```
  snap install powershell --classic
  ```
  
#### 2) Start PS
  - if downloaded, installed manually
    ```
    /opt/microsoft/powershell/7/pwsh
    ```
  - if installed using Snap
    ```
    powershell
    ```

#### 3) Install SimplySql
```
Install-Module -Name SimplySql -Scope CurrentUser
```

#### 4) Import module
```
Import-Module SimplySQL
```

#### 5) Optional: confirm module is imported
```
Get-Module SimplySQL
```

#### 5) Download script
```
wget https://github.com/HappyRogue658/fix-nextcloud-file-creation-date/raw/main/fix%20nextcloud%20file%20creation%20date.ps1
```

#### 6) Optional: provide database credentials  
If you run the script multiple times, it now makes sense to enter SQL credentials, before running the script  
```
$cred = get-credential
```

#### 7) Run script  
see below for options
```
& './fix nextcloud file creation date.ps1'
```

#### 8) Run occ scan  
example
```
sudo -u www-data php '/var/www/nextcloud/occ' files:scan --all
```
#### 9) optional: clean-up  
  - remove script
    ```
    rm 'fix nextcloud file creation date.ps1'
    ```
  - remove PS module SimplySQL  
    in PS, run
    ```
    Uninstall-Module -Name SimplySql
    ```

   - remove PowerShell
     - if downloaded, installed manually
       - remove PS install file
         ```
         rm 'powershell_7.3.0-1.deb_amd64.deb'
         ```
       - uninstall PS
         ```
         sudo apt-get remove powershell
         ```
     - if installed using Snap
       ```
       snap remove powershell
       ```

### Examples  
list files that will get their date changed
```
& './fix nextcloud file creation date.ps1' `
	-dbserver '127.0.0.1' `
	-dbname 'owncloud' `
	-dataDirectory '/media/owncloud_storage/data/' `
	-action 'list'
```

list files that will get their date changed, table, show file name, create date in file system, and mtime in DB
```
& './fix nextcloud file creation date.ps1' `
	-dbserver '127.0.0.1' `
	-dbname 'owncloud' `
	-dataDirectory '/media/owncloud_storage/data/' `
	-action 'list' `
	| select-object fileName, CreationTime, epochToDateTime
```
 
show touch command syntax but do not touch files
```
& './fix nextcloud file creation date.ps1' `
	-dbserver '127.0.0.1' `
	-dbname 'owncloud' `
	-dataDirectory '/media/owncloud_storage/data/' `
	-action 'changeDateSimulated'
```

change create date ('Modify' date in Linux) to the date retrieved from DB
```
& './fix nextcloud file creation date.ps1' `
	-dbserver '127.0.0.1' `
	-dbname 'owncloud' `
	-dataDirectory '/media/owncloud_storage/data/' `
	-action 'changeDate'
```

### Troubleshooting
list files that were found in DB but were not found in file system
```
& './fix nextcloud file creation date.ps1' `
	-dbserver '127.0.0.1' `
	-dbname 'owncloud' `
	-dataDirectory '/media/owncloud_storage/data/' `
	-action 'list' `
	| where-object {$_.fileName -eq $null}
```

same as above but count how many file are affected
```
& './fix nextcloud file creation date.ps1' `
	-dbserver '127.0.0.1' `
	-dbname 'owncloud' `
	-dataDirectory '/media/owncloud_storage/data/' `
	-action 'list' `
	| where-object {$_.fileName -eq $null} `
	| measure-object
```







