##
# REQUIREMENTS: Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest
#

Param(
	[Boolean] $List = $false
)

# Login
Write-Output "___ Login ___"
az login
Write-Output ""

# Task
$Interfaces = az network nic list --query '[?virtualMachine==`null`].[id]' -o tsv
$Progress = 0

foreach ($Interface in $Interfaces) {
	$Progress++
	Write-Output "___ Resource ($Progress/$($Interfaces.length)) ___"
	if (!$List) {
		Write-Output "Looking for Resource-Connections..."
		$NIC = az network nic show --ids $Interface --query 'id'
		$PIP = az network nic show --ids $Interface --query 'ipConfigurations[0].publicIpAddress.id'
		$NSG = az network nic show --ids $Interface --query 'networkSecurityGroup.id'
		Write-Output "Deleting Network-Interface: $($NIC)"
		az network nic delete --ids $NIC
		Write-Output "Deleting Public-IP-Adress: $($PIP)"
		az network public-ip delete --ids $PIP
		Write-Output "Deleting Network-Security-Group: $($NSG)"
		az network nsg delete --ids $NSG
	}
	else {
		az network nic show --ids $Interface --query '{NIC: id, PIP: ipConfigurations[0].publicIpAddress.id, NSG: networkSecurityGroup.id}'
	}
	Write-Output ""
}

# End
Read-Host -Prompt "Press Enter to exit"
