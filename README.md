# PowerBI Service: PowerShell scripts for analysis and batch processing

## Summary:
* **PowerBI-Inventory.ps1:** Basic script to pull workspace data and reports from each workspace - downloads each file to json, processes and deletes at end. Can be set to diagnostic mode to not delete files after running.
* **PowerBI-RefreshSchedules.ps1:** Runs through workspaces and filters out any workspaces with qa/dev/poc in the title, then accesses each dataset and pulls the refresh schedule. Should probably build in a time conversion to make everything on one time zone.
* **PowerBI-Parameters.ps1:** Runs through workspaces and filters out any workspaces with qa/dev/poc in the title, then accesses each dataset and pulls the parameters.

## Backlog:
### Updates Existing:
* RefreshSchedules.ps1 -> Convert all time to UTC?

### Create New:
* Refresh stopper - Deactivate upcoming refreshes (if server load is getting too hot)
