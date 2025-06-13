#--------------------------------------------------------------------------------------------------
# Script created by Phil Perrin with much support from Captain Google.
# Last updated 6/11/25
# Version: 1.0
#
# Purpose:
# Query Power BI Service to extract the users in each workspace.
# Does not include 'My Workspace'.
#
# Instructions:
# 1. Run PowerShell as admin.
# 2. First time use: 
#    a. Install the Power BI PowerShell cmdlets (Install-Module MicrosoftPowerBIMgmt)
#       https://docs.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps.
# 3. Adjust parameters as needed.
# 4. Run the script - user will be prompted for the Power BI account to use.
# 5. Optional: Give Phil some feedback on how to make this better.
#
#--------------------------------------------------------------------------------------------------

# Connect to Power BI. User will be prompted to select the account to use.
Connect-PowerBIServiceAccount

# First, get workspaces
Write-Host "Gathering workspaces."
$allGroups = Invoke-PowerBIRestMethod -Url 'groups' -Method Get
$allGroups = $allGroups | ConvertFrom-Json

$w_data = foreach ($row in $allGroups.value){
    [PSCustomObject] @{
    w_id = $row.id
    w_name = $row.name
    }
}

Write-Host "Done!"

$w_datacount = $w_data.Count

Write-Host "Getting users from each workspace ($w_datacount)."

$w_users = foreach ($row in $w_data){
    $g_id = $row.w_id
    $w_name = $row.w_name
    $w_result = Invoke-PowerBIRestMethod -Url "groups/$g_id/users" -Method Get | ConvertFrom-Json
    
    foreach ($row in $w_result.value){
        $email = $row.emailAddress
        $access = $row.groupUserAccessRight
        $name = $row.displayName
        $identifier = $row.identifier
        $type = $row.principalType
            [PSCustomObject] @{
                emailAddress = $email
                access = $access
                name = $name
                id = $identifier
                type = $type
                ws_id = $g_id
                ws_name = $w_name
            }
        }
    
}
$w_users | Select-Object -Property ws_name,ws_id,name,emailAddress,id,access,type | Export-Csv -Path ".\ws_users.csv"  -NoTypeInformation -Force
Write-Host "Finished! Please check your local directory for a file named ws_users.csv"