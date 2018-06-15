##
# REQUIREMENTS: Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest
#

# Login
$User = "VALUE"
Write-Output "___ Login ___"
Write-Output "User: $($User)"
az login -u $User
Write-Output ""

# Task
$Progress = 0
Write-Output "Searching for unattached Network Interfaces..."
$Interfaces = az network nic list --query '[?virtualMachine==`null`].[id]' -o tsv
Write-Output "Found $($Interfaces.length) unattached Network Interfaces."
Write-Output ""
If($Interfaces.length -ne 0) {
	$Action = Read-Host -Prompt "Do you want to delete all Network Interfaces? (y/n)"
	foreach ($Interface in $Interfaces) {
		$Progress++
		Write-Output "___ Resource ($Progress/$($Interfaces.length)) ___"
		if ($Action -eq "y") {
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
}

# End
Read-Host -Prompt "Press Enter to exit"
