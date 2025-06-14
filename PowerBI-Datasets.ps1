#--------------------------------------------------------------------------------------------------
# Script created by Phil Perrin with much support from Captain Google.
# Last updated 6/13/25
# Version: 1.0
#
# Purpose:
# Query Power BI Service to obtain dataset information from each workspace.
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

# First, get workspaces and filter out so only prod
Write-Host "Gathering workspaces"
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

# Now that we have the list of workspaces we need, let's get the datasets in each.
Write-Host "Getting datasets from each workspace ($w_datacount)."
$w_datasets = foreach ($row in $w_data){
    $g_id = $row.w_id
    $w_name = $row.w_name
    $w_result = Invoke-PowerBIRestMethod -Url "groups/$g_id/datasets" -Method Get | ConvertFrom-Json
    
    [PSCustomObject] @{
        ws_id = $g_id
        ws_name = $w_name
        d_value = $w_result.value
    }
}

$dataset_obj = foreach($row in $w_datasets){
    $ws_id = $row.ws_id
    $ws_name = $row.ws_name
    foreach($row2 in $row.d_value){
        $ds_id = $row2.id
        $ds_name = $row2.name
        $ds_url = $row2.WebUrl
        $ds_cfg = $row2.configuredBy

        [PSCustomObject] @{
            ws_id = $ws_id
            ws_name = $ws_name
            ds_id = $ds_id
            ds_name = $ds_name
            ds_url = $ds_url
            ds_cfg = $ds_cfg
            }
        }
    }

$dataset_obj | Select-Object -Property ws_id,ws_name,ds_id,ds_name,ds_url,ds_cfg | Export-Csv -Path ".\datasets.csv"  -NoTypeInformation -Force

Write-Host "Output complete. Please find the file 'datasets.csv' in the local directory."