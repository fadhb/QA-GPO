# QA-GPO.ps1
## Powershell QA script for updates to GPOs which install software
### Requires SDM cmdlets to be available

Prompts for a number of GPO friendly names then forms a list of all unique scopes where these are linked. For each scope a GPO link order report is created. The first GPO entered is taken to be the primary, a html report of this GPO is exported. Outputs to a file called <gpoName>.log and <GPO Friendlyname>.html 

Enter a single argument of filename to have it read GPO names from a text file.
