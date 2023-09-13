
# Get-SharesAndACLs.ps1

This PowerShell script retrieves a list of all Windows computers in the Active Directory domain and checks if they are online. For each online computer, it retrieves a list of all shares and exports the results to a CSV file. It then retrieves the ACL for each share and exports the results to another CSV file.

## Usage

1. Open PowerShell on the computer where the script will be run.
2. Navigate to the directory where the script is saved.
3. Run the script by typing `.\Get-SharesAndACLs.ps1 -CSVOutputFolder 'C:\ShareLists'`.
4. The script will scan the Active Directory domain for online computers and their shares.
5. The output will be saved to a CSV file in the specified folder.

## Parameters

- `CSVOutputFolder`: Specifies the folder where the CSV file should be saved. The default value is `c:\temp`.

## Notes

- This script requires PowerShell 3.0 or later.
- This script requires administrator privileges on the computer where it is run.
- This script may take several minutes to complete, depending on the size of the Active Directory domain.

## Example

```powershell
.\Get-SharesAndACLs.ps1 -CSVOutputFolder 'C:\ShareLists'