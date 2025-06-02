#--------------------------------------------------------------------------------------------------
# Script created by Phil Perrin with much support from Captain Google.
# Last updated 5/31/25
# Version: 1.0
#
# Purpose:
# Query Power BI Service to extract the refresh schedules of each dataset in prod workspaces
# Does not include 'My Workspace' or non-Prod workspaces. Does not include Usage Metric reports.
#
# Instructions:
# 1. Run PowerShell as admin.
# 2. First time use: 
#    a. Install the Power BI PowerShell cmdlets (Install-Module MicrosoftPowerBIMgmt)
#       https://docs.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps.
#    b. Install the Join-Object cmdlets (Install-Module -Name Join-Object)
# 3. Adjust parameters as needed.
# 4. Run the script - user will be prompted for the Power BI account to use.
# 5. Optional: Give Phil some feedback on how to make this better.
#
#--------------------------------------------------------------------------------------------------

# Connect to Power BI. User will be prompted to select the account to use.
Connect-PowerBIServiceAccount

# First, get workspaces and filter out so only prod
Write-Host "Gathering workspaces and filtering out dev/qa/pocs."
$allGroups = Invoke-PowerBIRestMethod -Url 'groups' -Method Get
$allGroups = $allGroups | ConvertFrom-Json

$w_data = foreach ($row in $allGroups.value){
    [PSCustomObject] @{
    w_id = $row.id
    w_name = $row.name
    }
}

$w_data = $w_data | Where-Object { $_.w_name -notlike "*dev*" }
$w_data = $w_data | Where-Object { $_.w_name -notlike "*qa*" }
$w_data = $w_data | Where-Object { $_.w_name -notlike "*poc*" }
Write-Host "Done!"

$w_datacount = $w_data.Count

# Now that we have the list of workspaces we need, let's get the datasets in each.
Write-Host "Getting datasets from each workspace ($w_datacount)."
$w_datasets = foreach ($row in $w_data){
    $g_id = $row.w_id
    $w_name = $row.group
    $w_result = Invoke-PowerBIRestMethod -Url "groups/$g_id/datasets" -Method Get
    $w_result = $w_result | ConvertFrom-Json
    
    [PSCustomObject] @{
        d_value = $w_result.value
    }
}

# A bit of a mess, but with that data, let's convert the output into something usable - keeping the dataset, group id, name and if the dataset is refreshable.
$dataset_obj = foreach ($row in $w_datasets.d_value){
[PSCustomObject] @{
        d_id = $row.id
        d_name = $row.name
        w_id = $row.webUrl.Substring(31,36)
        isRefreshable = $row.isRefreshable
    }
}
Write-Host "Done!"

# Keep only the refreshable datasets
$dataset_obj2 = $dataset_obj | Where-Object { $_.isRefreshable -notlike "FALSE" }
$dataset_obj2 = $dataset_obj2 | Where-Object { $_.d_name -notlike "*usage metrics*"}

# Join the group name back to dataset_obj
$dataset_obj2 = $dataset_obj2 | LeftJoin $w_data -On w_id

$ds_o2_count= $dataset_obj2.count

Write-Host "Getting refresh schedule info from each dataset ($ds_o2_count)."
# Using the dataset id and the group id, pull the refresh schedule on each dataset that is refreshable.
$allscheds = foreach ($roww in $dataset_obj2) {
    $workspaceid = $roww.w_id
    $datasetid = $roww.d_id
    $dataset_name = $roww.d_name
    $workspace_name = $roww.w_name

    $refreshscheds = Invoke-PowerBIRestMethod -Url "groups/$workspaceid/datasets/$datasetid/refreshSchedule" -Method Get
    $refreshschedsconv = $refreshscheds | ConvertFrom-Json
    
    [PSCustomObject] @{
        datasetid = $datasetid
        workspace_id = $workspaceid
        dataset_name = $dataset_name
        workspace_name = $workspace_name
        enabled = $refreshschedsconv.enabled
        localTimeZoneId = $refreshschedsconv.localTimeZoneId
        notifyOption = $refreshschedsconv.notifyOption
        refresh_days = $refreshschedsconv.days
        refresh_times = $refreshschedsconv.times
        }
}
Write-Host "Done!"

Write-Host "Let's put all the refresh times into one column."
$allscheds_time = foreach($row in $allscheds){
    $datasetid = $row.datasetid
    $workspace_id = $row.workspace_id
    $dataset_name = $row.dataset_name
    $workspace_name = $row.workspace_name
    $enabled = $row.enabled
    $localTimeZoneId = $row.localTimeZoneId
    $notifyOption = $row.notifyOption

    foreach($inner in $row.refresh_times){
        $r_times = $inner

        foreach($inner2 in $row.refresh_days){
            $r_days = $inner2

            [PSCustomObject] @{
                datasetid = $datasetid
                workspace_id = $workspace_id
                dataset_name = $dataset_name
                workspace_name = $workspace_name
                enabled = $enabled
                localTimeZoneId = $localTimeZoneId
                notifyOption = $notifyOption
                r_days = $r_days
                r_times = $r_times
                }
            }
        }
    }

$result_count = $allscheds_time.count
Write-Host "Done! Exporting results ($result_count)."
# Export results to file.
$allscheds_time | Select-Object -Property datasetid,dataset_name,workspace_id,workspace_name,enabled,localTimeZoneId,notifyOption,r_days,r_times | Export-Csv -Path ".\dataset_refresh_schedule.csv"  -NoTypeInformation -Force

Write-Host "Output complete. Please find the file 'dataset_refresh_schedule.csv' in the local directory."