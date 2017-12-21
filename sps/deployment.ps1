Param(
	[String] $Region = "dev",
	[String] $Description = "undefined",
	[String] $Language = "undefined",
	[Int] $VirtualMachineCount = 10,
	[Boolean] $Debug = $false
)

# __________________________________________________
#
# Setup
#
$StorageKey = "VALUE"
$StorageName = "VALUE"
$StorageContainer = "VALUE"
$FileTemplate = "vm.json"
$FileDefaults = "vm.parameters.json"
$Regions = @("ap", "ger", "isr", "na", "sw", "uk", "dev")
$Languages = @("en", "de", "fr")
$TimeZones = @{
	"ap" = "E. Australia Standard Time";
	"ger" = "W. Europe Standard Time";
	"isr" = "W. Europe Standard Time";
	"na" = "Pacific Standard Time";
	"sw" = "W. Europe Standard Time";
	"uk" = "GMT Standard Time";
	"dev" = "W. Europe Standard Time"
}

# __________________________________________________
#
# Parameter Checks
#
function checkParameterValue($value, $allowed) {
	$found = $false
	foreach ($item in $allowed) {
		if ($value -eq $item) {
			$found = $true
		}
	}
	$found
}
# Region
if ($Debug) { Write-Output "__DEBUG__: Looking for available region." }
if ((checkParameterValue $Region $Regions) -ne $true) {
	Write-Error "Region not found."
	exit
}
# Language
if ($Debug) { Write-Output "__DEBUG__: Looking for available language." }
if ((checkParameterValue $Language $Languages) -ne $true) {
	Write-Error "Language not found."
	exit
}

# __________________________________________________
#
# Connection
#
if ($Debug) { Write-Output "__DEBUG__: Creating connection." }
$Connection = Get-AutomationConnection -Name "AzureRunAsConnection"
$Account = Add-AzureRmAccount `
	-ServicePrincipal `
	-TenantId $Connection.TenantId `
	-ApplicationId $Connection.ApplicationId `
	-CertificateThumbprint $Connection.CertificateThumbprint

# __________________________________________________
#
# Storage
#
if ($Debug) { Write-Output "__DEBUG__: Looking for storage." }
$Context = New-AzureStorageContext `
	-StorageAccountKey $StorageKey `
	-StorageAccountName $StorageName
$StorageAccount = Set-AzureRmCurrentStorageAccount -Context $Context

# __________________________________________________
#
# Variables
#
$Date = ([datetime]::now).tostring("dd.MM.yyyy-HH:mm:ss")
$TimeZone = $TimeZones.Get_Item($Region)
$ResourceGroupName = "Demo_$($Region.ToUpper())_RG"
$Template = New-AzureStorageBlobSASToken -Container $StorageContainer -Blob $FileTemplate -Permission r -ExpiryTime (Get-Date).AddHours(1.0) -FullUri
$Defaults = (Get-AzureStorageBlobContent -Container $StorageContainer -Blob $FileDefaults).ICloudBlob.DownloadText() | ConvertFrom-Json
if ($Description -eq "undefined") {
	$Description = $Defaults.parameters.Description.value
}
if ($Language -eq "undefined") {
	$Language = $Defaults.parameters.Language.value
}
$VirtualMachineName = "$($Region)-$($Description)"

# __________________________________________________
#
# Slot
#
$Slot = 1
if ($Description -ne "clean") {
	if ($Debug) { Write-Output "__DEBUG__: Looking for available slot." }
	while ($Slot -le $VirtualMachineCount) {
		$format = "{0:D2}" -f $Slot
		$used = $false
		foreach ($item in $Languages) {
			$name = "$($VirtualMachineName)-$($item)-$($format)"
			if (Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $name -ErrorAction SilentlyContinue) {
				$Slot++
				$used = $true
				break
			}
		}
		if ($used -eq $false) {
			break
		}
	}
}
else {
	if ($Debug) { Write-Output "__DEBUG__: Looking for existing VMs." }
	foreach ($item in $Languages) {
		$name = "$($VirtualMachineName)-$($item)"
		if (Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $name -ErrorAction SilentlyContinue) {
			Write-Error "Clean VM already deployed."
			exit
		}
	}
}

# __________________________________________________
#
# Deployment
#
if (($Slot -gt $VirtualMachineCount) -and ($Description -ne "clean")) {
	Write-Error "No free slot available."
	exit
}
else {
	$Slot = "{0:D2}" -f $Slot
	$VirtualMachineName = "$($VirtualMachineName)-$($Language)"
	if ($Description -ne "clean") {
		$VirtualMachineName = "$($VirtualMachineName)-$($Slot)"
	}
	if ($Debug) {
		Write-Output "___ Parameters ___"
		Write-Output "Date: $($Date)"
		Write-Output "Region: $($Region)"
		Write-Output "TimeZone: $($TimeZone)"
		Write-Output "Description: $($Description)"
		Write-Output "Language: $($Language)"
		Write-Output "ProductName: $($Defaults.parameters.ProductName.value)"
		Write-Output "ProductVersion: $($Defaults.parameters.ProductVersion.value)"
		Write-Output "VirtualMachineSlot: $($Slot)"
		Write-Output "VirtualMachineAdminUserName: $($Defaults.parameters.VirtualMachineAdminUserName.value)"
		Write-Output "VirtualMachineAdminPassword: $($Defaults.parameters.VirtualMachineAdminPassword.value)"
		Write-Output "DomainUserName: $($Defaults.parameters.DomainUserName.value)"
		Write-Output "DomainPassword: $($Defaults.parameters.DomainPassword.value)"
	}
	else {
		$VirtualMachine = New-AzureRmResourceGroupDeployment `
			-ResourceGroupName $ResourceGroupName `
			-TemplateFile $Template `
			-Date $Date `
			-Region $Region `
			-TimeZone $TimeZone `
			-Description $Description `
			-Language $Language `
			-ProductName $Defaults.parameters.ProductName.value `
			-ProductVersion $Defaults.parameters.ProductVersion.value `
			-VirtualMachineSlot $Slot `
			-VirtualMachineAdminUserName $Defaults.parameters.VirtualMachineAdminUserName.value `
			-VirtualMachineAdminPassword $Defaults.parameters.VirtualMachineAdminPassword.value `
			-DomainUserName $Defaults.parameters.DomainUserName.value `
			-DomainPassword $Defaults.parameters.DomainPassword.value
	}
}
