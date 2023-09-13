<#
.SYNOPSIS
    This PowerShell script retrieves a list of all Windows computers in the Active Directory domain and checks if they are online. For each online computer, it retrieves a list of all shares and exports the results to a CSV file. It then retrieves the ACL for each share and exports the results to another CSV file.

.PARAMETER CSVOutputFolder
    Specifies the folder where the CSV file should be saved. The default value is 'c:\temp'.

.NOTES
    File Name: Get-SharesAndACLs.ps1
    Author: DPO
    Version: 1.0
    Date Created: 13/09/2023
    Date Modified: 13/09/2023

.EXAMPLE
    PS C:\> .\Get-SharesAndACLs.ps1 -CSVOutputFolder 'C:\ShareLists'

    This example retrieves a list of all Windows computers in the Active Directory domain and exports a list of all shares for each online computer to a CSV file in the 'C:\ShareLists' folder.
#>
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator
param (
    [alias('OutPath')]
    [string]$CSVOutputFolder = 'c:\temp'
)

$computerNames = (Get-ADComputer -Filter { OperatingSystem -Like "*Windows*" }).Name

$shareListFilePath = Join-Path -Path $CSVOutputFolder -ChildPath 'ShareList.csv'

# Delete previous Share list.
if (Test-Path -Path $shareListFilePath) {
    Remove-Item -Path $shareListFilePath -Force
}

foreach ($computerName in $computerNames) {
    Write-Host ('Processing {0}...' -f $computerName)

    # Test if device is online
    if (!(Test-Connection -ComputerName $computerName -Count 1 -Quiet)) {
        Write-Host ('{0} is offline.' -f $computerName)
        continue
    }

    try {
        $shares = Get-WmiObject -Class Win32_Share -ComputerName $computerName -ErrorAction Stop | Where-Object { $_.Name -notMatch '^(ADMIN\$|IPC\$|print\$|prnproc\$|[a-zA-Z]\$)' -and $_.Path -notMatch ',LocalsplOnly' } | Select-Object PSComputerName, Name, Path
    }
    catch {
        $errMsg = ($_.Exception.Message).Trim()
        Write-Host ('Error getting shares on {0}: {1}' -f $computerName, $errMsg) -ForegroundColor Yellow
        continue
    }

    if (!$shares) {
        Write-Host ('{0} has no shares.' -f $computerName)
        continue
    }
    else {
        foreach ($share in $shares) {
            Write-Host ('{0} has share {1} at {2}' -f $share.PSComputerName, $share.Name, $share.Path)
        }
        $shares | Export-Csv -Path $shareListFilePath -NoTypeInformation -Append
    }
}

# Start a remote session to the first PSComputer listed in teh CSV and return the ACL for the folder provided in the Path
$shares = Import-Csv -Path $shareListFilePath
$aclListFilePath = Join-Path -Path $CSVOutputFolder -ChildPath 'ShareACLs.csv'
$accessList = @()

foreach ($share in $shares) {
    Write-Host ('{0} has share {1} at {2}' -f $share.PSComputerName, $share.Name, $share.Path)
    $session = New-PSSession -ComputerName $share.PSComputerName
    $accessList += Invoke-Command -Session $session -ScriptBlock { Get-Acl -Path $args[0] } -ArgumentList $share.Path
    Remove-PSSession -Session $session
}

# Use the accessList to create a CSV file that contains the ACL for each share, with the assigned accesses in plain English
$accessList | Select-Object -Property PSComputerName, Path, Owner, AccessToString | Export-Csv -Path $aclListFilePath -NoTypeInformation

# Remove all occurrences of the text "Microsoft.PowerShell.Core\FileSystem::" from the csv file
(Get-Content -Path $aclListFilePath) -replace 'Microsoft.PowerShell.Core\\FileSystem::', '' | Set-Content -Path $aclListFilePath