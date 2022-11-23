# fix-nextcloud-file-creation-date
- fixes file creation date set back to 1970 by bugged version of nextcloud client
(see https://help.nextcloud.com/t/desktop-client-3-4-0-destroys-local-time-stamp-and-keeps-uploading-data-to-server )

- It is best to have a backup of nextcloud DB and data directory before running the script!

- This script overrides the file system file creation date of files in the nextcloud data directory with the date taken from nextcloud DB

- Uses SQL query by wwe (https://help.nextcloud.com/u/wwe)
see https://help.nextcloud.com/t/desktop-client-3-4-0-destroys-local-time-stamp-and-keeps-uploading-data-to-server/128512/93

- tested on Ubuntu with MySQL DB

- This requires PowerShell as well as the PS module SimplySql

### fixing file creation dates

1) download PowerShell
```
wget https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell_7.3.0-1.deb_amd64.deb
```

2) Install the downloaded package
```
sudo dpkg -i powershell_7.3.0-1.deb_amd64.deb
```

3) Resolve missing dependencies and finish the install (if necessary)
```
sudo apt-get install -f
```

4) start PS
```
/opt/microsoft/powershell/7/pwsh
```

5) Install SimplySql
```
Install-Module -Name SimplySql -Scope CurrentUser
```

6) import module
```
import-Module SimplySQL
```

7) confirm module is imported
```
Get-Module SimplySQL
```

8) download 'fix nextcloud file creation date.ps1' script
```
wget https://github.com/HappyRogue658/fix-nextcloud-file-creation-date/raw/main/fix%20nextcloud%20file%20creation%20date.ps1
```

9) optional: if you run the script multiple times, it now makes sense to enter SQL credentials, before running the script
```
$cred = get-credential
```

10) run script
see below for options
```
& './fix nextcloud file creation date.ps1'
```

11) run occ scan
```
sudo -u www-data php occ files:scan --all
```
example
```
sudo -u www-data php '/var/www/nextcloud/occ' files:scan --all
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

troubleshooting
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







