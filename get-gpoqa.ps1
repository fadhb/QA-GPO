<#

 Name:		get-gpoqa.ps1

 Author:	Jonathan Headen

 Date:		07/01/09

 Purpose:   For use with GPO delivered software installation.  If a GPO is being updated this script 
            will provide quality check that the dependent GPOs are suitably linked and that superceded  
            GPOs are removed 

 Comment:	Prompts for a number of GPO friendly names then forms a list of all unique
		    scopes where these are linked. For each scope a GPO link order report is created.
		    The first GPO entered is taken to be the primary, a html report of this GPO is exported.
		    Outputs to a file called <gpoName>.log and <GPO Friendlyname>.html
		    Enter a single argument of filename to have it read GPO names from a text file.
            Requires SDM GPO cmdlets to be available
		
#>

clear

$location=(get-location).tostring()
If ($location.length -gt 3){$location = $location+"\"}
$global:allgpos= @()
$global:paths= @()
$allresults= @()


Function get-gpoinfo {
	if ($init)
		{
		$GPONAME=Read-host "What is the GPO Friendly name for dependent and superceeded GPO'S? (leave blank if there are no more)"	
		if($gpoName){$global:allgpos=$global:allgpos + $gponame;get-gpoinfo}
		}
	else
		{
		$GPONAME=Read-host "What is the GPO Friendly name?"
		$init=$true
		if($gpoName){$global:allgpos=$global:allgpos + $gponame; get-gpoinfo}
		}
	}

if(!$args){get-gpoinfo} else {$global:allgpos = Get-Content $args[0]}

clear

if ($global:allgpos.gettype().basetype.tostring() -ne "System.array")
	{
	[array]$global:allgpos=$global:allgpos	
	}


write-host -foregroundcolor yellow ("=" * (15 + $global:allgpos[0].length))

Write-host -foregroundcolor green "`nPrimary GPO is"$global:allgpos[0]
Write-host -foregroundcolor green "`n`t All Other GPOs are either superceeded GPOs or Dependency GPOS"
Write-host -foregroundcolor green "`t In order to differentiate between these please identify the `n`t superceeded packages from the list below. `n"
write-host -foregroundcolor yellow ("=" * (15 + $global:allgpos[0].length))
for ($i = 1; $i -lt $global:allgpos.length; $i++) {Write-host -foregroundcolor green "$i `t"$global:allgpos[$i]}
write-host -foregroundcolor yellow ("=" * (15 + $global:allgpos[0].length))
$return=Read-host "`nWhich GPO's are the superceded packages `n(enter the numbers seperated by spaces)"
$superceededarray=$return.split()

for ($i = 1; $i -lt $global:allgpos.length; $i++){if ($superceededarray -contains $i)
		{[array]$superceededgpos=$superceededgpos + $global:allgpos[$i]}
		else
		{[array]$dependencygpos=$dependencygpos + $global:allgpos[$i]}
	}

clear
Write-host -foregroundcolor green "Primary GPO"
write-host $global:allgpos[0]
Write-host -foregroundcolor green "`nSuperceeded Packages:"
$superceededgpos
Write-host -foregroundcolor green "`nDependency Packages:"
$dependencygpos

$prigpo =$global:allgpos[0].trimend()
$outputfile=$global:allgpos[0]+".log"
	
Out-file $outputfile -inputobject "========================"
Out-file $outputfile -inputobject "All GPOS Listed to Check" -append
Out-file $outputfile -inputobject "========================" -append
Out-file $outputfile -inputobject "" -append
Out-file $outputfile -inputobject "Primary GPO to be QA'd" -append
Out-file $outputfile -inputobject "----------------------" -append
Out-file $outputfile -inputobject $prigpo -append
Out-file $outputfile -inputobject "" -append
Out-file $outputfile -inputobject "Superceeded" -append
Out-file $outputfile -inputobject "-----------" -append
foreach ($item in $superceededgpos){Out-file $outputfile -inputobject $item -append}
Out-file $outputfile -inputobject "" -append
Out-file $outputfile -inputobject "Dependencies" -append
Out-file $outputfile -inputobject "------------" -append
foreach ($item in $dependencygpos){Out-file $outputfile -inputobject $item -append}

Out-file $outputfile -inputobject "" -append


write-host -foregroundcolor yellow "exporting $prigpo and retrieving security info"
Out-SDMgpsettingsreport -Name $PriGPO -FileName "$location$prigpo.html" -ReportHTML

$length = "Details for $prigpo".length
Out-file $outputfile -inputobject "" -append
Out-file $outputfile -inputobject ("=" * $length) -append
Out-file $outputfile -inputobject "Details for $prigpo" -append
Out-file $outputfile -inputobject ("=" * $length) -append 
Out-file $outputfile -inputobject "" -append
$content = Get-Content $location$prigpo.html
$GPOStatus ="(<tr><td scope=`"row`">GPO Status</td><td>)(?<status>.*)(</td></tr>)"
$MsiPath ="(<tr><td>Deployment source</td><td>)(?<source>.*)(</td></tr>)"
$MstPath = "<tr><th scope=`"col`">Transforms</th></tr>"
$mstFilter="(<tr><td>)(?<mstpath>.*)(</td></tr>)"
foreach ($line in $content)
	{
	if ($mstFlag)
		{
		if ($line -match $mstfilter){$QAmst=$matches.mstpath}
		$mstflag=$False
		}
	if ($line -match $GPOStatus) {$QAStatus=$matches.status }
	if ($line -match $MsiPath) {$QASource=$matches.source }	
	if ($line -match $MstPath) {$MSTFlag=$true }	
	}
If ($QAStatus) {Out-file $outputfile -inputobject "Status: $QAStatus" -Append}
If ($QASource) 
	{
	Out-file $outputfile -inputobject "MST: $QASource" -Append
	if (Test-Path $QASource)
		{Out-file $outputfile -inputobject "MSI file exists" -Append}
		else
		{Out-file $outputfile -inputobject "MSIFILE NOT PRESENT" -Append}
	}
If ($QAmst -ne "None") 
	{
	Out-file $outputfile -inputobject "MST: $QAmst" -Append
	if (Test-Path $QAmst)
		{Out-file $outputfile -inputobject "MST file exists" -Append}
		else
		{Out-file $outputfile -inputobject "MSTFILE NOT PRESENT" -Append}
	}
	else {Out-file $outputfile -inputobject "MST: Not Defined" -Append}

$length = "Permissions set for $prigpo".length
Out-file $outputfile -inputobject "" -append
Out-file $outputfile -inputobject ("=" * $length) -append
Out-file $outputfile -inputobject "Permissions set for $prigpo" -append
Out-file $outputfile -inputobject ("=" * $length) -append 
Out-file $outputfile -inputobject "" -append

$gpsec=get-sdmgposecurity -name $prigpo
$gpsec  |% {if ($_.permission -notmatch "Delete")
				{
				out-file $outputfile -InputObject $_.permission -Append -Width 150
				out-file $outputfile -InputObject $_.Trustee -Append -Width 150
				out-file $outputfile -InputObject "" -Append -Width 150
				if ($_.permission -eq "PermGPOApply")
					{
					[array]$primarygroups=$primarygroups+$_.trustee
					}
				}
			}

if ($dependencygpos.length -gt 0){
	$length = 61 
	Out-file $outputfile -inputobject "" -append
	Out-file $outputfile -inputobject ("=" * $length) -append
	Out-file $outputfile -inputobject "Permissions for primary gpo groups as set on the dependencies" -append
	Out-file $outputfile -inputobject ("=" * $length) -append 
	Out-file $outputfile -inputobject "" -append

	foreach ($dpgpo in $dependencygpos)
		{Write-host -foregroundcolor yellow "Getting Security Info for $dpgpo"
		Out-file $outputfile -inputobject "Dependency GPO: $dpgpo" -append
		$dpSec=get-sdmgposecurity -name $dpgpo
		foreach ($dpPerm in $dpsec)
			{		
			if ($primarygroups -contains $dpPerm.trustee)
				{
				Write-host -foregroundcolor magenta $dpPerm.trustee
				out-file $outputfile -InputObject $dpPerm.permission -Append -Width 150
				out-file $outputfile -InputObject $dpPerm.Trustee -Append -Width 150
				out-file $outputfile -InputObject "" -Append -Width 150
				}
			}
		}
}

$gpo =get-sdmgpo $prigpo.trimend() -native
	$selectgpo = ""|select-object Name,id	
	$selectgpo.Name= $gpo.displayname
	$selectgpo.id= $gpo.id
	[array]$allgpoids=$allgpoids+$selectgpo
	$gpolinks=get-sdmgplink -name $prigpo
	$gpolinks|%{[array]$global:paths=[array]$global:paths + $_.path}

if ($superceededgpos.length -gt 0)
	{
	foreach ($gponame in $superceededgpos) 
		{
		write-host -foregroundcolor yellow "getting $gponame linked OU info"
		$gpo =get-sdmgpo $GPONAME.trimend() -native
		$selectgpo = ""|select-object Name,id	
		$selectgpo.Name= $gpo.displayname
		$selectgpo.id= $gpo.id
		$allgpoids=$allgpoids+$selectgpo
		$gpolinks=get-sdmgplink -name $GPONAME
		$gpolinks|%{[array]$global:paths=[array]$global:paths + $_.path}	
		}
	}

if ($dependencygpos.length -gt 0)
	{
	foreach ($gponame in $dependencygpos) 
		{
		$gpo =get-sdmgpo $GPONAME.trimend() -native
		$selectgpo = ""|select-object Name,id	
		$selectgpo.Name= $gpo.displayname
		$selectgpo.id= $gpo.id
		$allgpoids=$allgpoids+$selectgpo
		}
	}



$uniquepaths=$global:paths |sort-object -unique
$uniquepaths|%{If ($_ -match "DC=aurtest")
			{If ($_ -match "OU=Test,DC=aurtest")
				{[array]$targetous=$targetous + $_}
			}
# Unremark the following code to accomodate DEV
#		ElseIf ($_ -match "DC=aurdev") 
# 		 	{If ($_ -match "OU=Test,DC=aurDev")
# 				{[array]$targetous=$targetous + $_}
#			}
		Else
			{[array]$targetous=$targetous + $_}
		}

Out-file $outputfile -inputobject "" -append
Out-file $outputfile -inputobject "===================" -append
Out-file $outputfile -inputobject "All scopes to Check" -append
Out-file $outputfile -inputobject "===================" -append
Out-file $outputfile -inputobject "" -append
$targetous |Out-file $outputfile -append -width 150

foreach ($scope in $targetous)
		{
		$gplinks=get-sdmgplink -scope $scope -native
		foreach ($link in $gplinks)
			{
			foreach ($gpoitem in $allgpoids)
				{
				if ($link.gpoid -eq $gpoitem.id)
					{
					$gpodata = ""|select-object scope,name,linkorder,enabled
					$gpodata.name = $gpoitem.name
					$gpodata.linkorder = $link.somlinkorder
					$gpodata.scope = $scope					
					$gpodata.enabled=$link.enabled
					$allresults= $allresults + $gpodata
					}
				}
			}
		}

Out-file $outputfile -inputobject "" -append
out-file $outputfile -inputobject "===========================" -append
out-file $outputfile -inputobject "GPO Linking sorted by Scope" -append
out-file $outputfile -inputobject "===========================" -append
Out-file $outputfile -inputobject "" -append

$allresults |format-list -groupby scope -property name,linkorder,enabled |out-file QAtempFile.log -append -Width 150
$tempfile = Get-content QAtempFile.log

foreach ($Line in $tempfile)
	{
	if ($line -match "Scope:")
		{
		Out-file $outputfile -inputobject "" -append
		Out-file $outputfile -inputobject "" -append
		out-file $outputfile -inputobject $line.trimstart() -append -Width 150
		out-file $outputfile -inputobject  ("-" * $line.length) -append -width 150
		}
	Elseif ($line.length -gt 0)	
		{
		out-file $outputfile -inputobject $line -append -Width 150
		}
	}

remove-item QAtempFile.log






