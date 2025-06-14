# PowerBI Service: PowerShell scripts for analysis and batch processing

## Summary:
* **PowerBI-Datasets.ps1:** Goes through each workspace and retrieves each dataset - exporting the list to a csv.
* **PowerBI-Inventory.ps1:** Basic script to pull workspace data and reports from each workspace - downloads each file to json, processes and deletes at end. Can be set to diagnostic mode to not delete files after running.
* **PowerBI-Parameters.ps1:** Runs through workspaces and filters out any workspaces with qa/dev/poc in the title, then accesses each dataset and pulls the parameters.
* **PowerBI-RefreshSchedules.ps1:** Runs through workspaces and filters out any workspaces with qa/dev/poc in the title, then accesses each dataset and pulls the refresh schedule.
* **PowerBI-Users.ps1:** Goes through workspaces and retrieves each user with permissions in each workspace, exporting the results to csv.

## Backlog:
### Updates Existing:
* RefreshSchedules.ps1 -> Convert all time to UTC

### Create New:
* Refresh stopper - Deactivate upcoming refreshes (if server load is getting too hot)
