#v1.02 Nov 23, 2022

param
(
  # variables define one or more parameters
  # this is a comma-separated list!
    [parameter(Mandatory=$false)] $action = 'list',     #'list' list files, change nothing
                                                        #'changeDateSimulated' show touch command
                                                        #'changeDate' change file creation date
    [parameter(Mandatory=$false)] $dbserver = '127.0.0.1',
    [parameter(Mandatory=$false)] $dbname = 'owncloud',
    [parameter(Mandatory=$false)] $dataDirectory = '/media/owncloud_storage/data/' #nextcloud data directory
)

#$cred = get-credential
import-Module SimplySQL
Open-MySqlConnection -Server $dbserver -Database $dbname -Credential $cred

#get users
$users = invoke-sqlquery -query "
    SELECT id, numeric_id from oc_storages
"

$filesWithVersion = invoke-sqlquery -query "
    SELECT f.fileid
        ,fv.fileid AS version_fileid
        ,f.fspath
        ,fv.fspath AS version_fspath
        ,versionpath
        ,f.size
        ,versionsize
        ,f.mtime
        ,f.storage
        ,f.filetime
        ,fv.change_time
        ,fv.original_mtime

    FROM (SELECT STORAGE,fileid
        ,path
        , TRIM(LEADING 'files/' FROM path) AS fspath
        ,size
        ,mtime
        , FROM_UNIXTIME(mtime) AS filetime
    FROM oc_filecache
    WHERE path LIKE 'files/%' AND mtime=0 
    #AND fileid=42091
    #LIMIT 1
    ) f

    JOIN (SELECT fileid
        , SUBSTRING_INDEX(TRIM(LEADING 'files_versions/' FROM path),'.v',1) AS fspath
        ,path as versionpath
        ,size AS versionsize
        ,mtime
        ,FROM_UNIXTIME(mtime) AS change_time
        ,SUBSTRING_INDEX(name,'.v',-1) AS original_mtime
        ,FROM_UNIXTIME(SUBSTRING_INDEX(name,'.v',-1)) AS original_time
        FROM oc_filecache
    WHERE path LIKE 'files_versions/%.v%') fv
    ON f.fspath=fv.fspath
"

$actualFiles = @() #list of files without versions

#find oldest mtime for file
foreach ($file in $filesWithVersion) {
    if ($actualFiles.length -eq 0) {
        #always add first file
        $actualFiles += $file #add this version to list of files           
    }
    else {
        #add more files if their fileid is new
        $actualFile = $actualFiles | where-object {$_.fileid -eq $file.fileid}

        if ($actualFile.fileid -ne $file.fileid) {
            $actualFiles += $file #add this version to list of files             
        }
        else {
            if ($file.original_mtime -gt 0) { #account for invalid mtimes 
                #this file already exists
                #check mtime, look for oldest mtime
                if ($actualFile.original_mtime -gt $file.original_mtime) {
                    #version's mtime is older than previously seen mtime
                    $actualFile.original_mtime = $file.original_mtime
                }
            }
        }
    }
}

#get file system path
$actualFiles | Add-Member -MemberType NoteProperty "path" -Value $null
$actualFiles | Add-Member -MemberType NoteProperty "touchSyntax" -Value $null
$actualFiles | Add-Member -MemberType NoteProperty "CreationTime" -Value $null
$actualFiles | Add-Member -MemberType NoteProperty "fileName" -Value $null
foreach ($file in $actualFiles) {
    $file.path += $dataDirectory 
    $user = $users | where-object {$_.numeric_id -eq $file.storage}
    $userDirectory =  $user.id
    $userDirectory = $userDirectory.replace('home::','')
    $file.path += $userDirectory
    $file.path += '/files/' + $file.version_fspath

    #does file exist?
    if (Test-Path -Path $file.path -PathType leaf) {
        #get file system file creation date
        $CreationTime = get-item $file.path | select-object CreationTime #this is 'Modify' date in Linux
        $CreationTime = Out-String -InputObject $CreationTime.CreationTime
        $CreationTime = $CreationTime.trim()
        $CreationTime = [DateTime]$CreationTime

        #get file name
        $file.CreationTime =  $CreationTime
        $file.fileName = get-item $file.path
        $file.fileName = ($file.fileName.basename + $file.fileName.extension)
        #$file.fileName = get-item $file.path | select-object Name  | Out-String #get file name
    }
    else {
        $warning = 'file: ' + $file.fspath + ' not found in: ' + $file.path
        Write-Warning $warning
    }

    #create touch syntax
    $file.touchSyntax = '-m --date=@' + $file.original_mtime + ' ' + $file.path
}

#present results
$actualFiles | Add-Member -MemberType NoteProperty "epochToDateTime" -Value $null
foreach ($file in $actualFiles) {
    $file.epochToDateTime = (Get-Date -Date "01-01-1970") + ([System.TimeSpan]::FromSeconds(($file.original_mtime)))
}

if ($action -eq 'list') {
    $actualFiles # | select-object fspath, original_mtime, epochToDateTime
}
if ($action -match 'changeDate') {
    foreach ($file in $actualFiles) {
        write-host '-m' ('--date=@' + $file.original_mtime) $file.path
        if ($action -eq 'changeDate') {
            #touch $touch
            write-host 'touch' '-m' ('--date=@' + $file.original_mtime) $file.path
            touch '-m' ('--date=@' + $file.original_mtime) $file.path
        }
        
    }
}

Close-SqlConnection