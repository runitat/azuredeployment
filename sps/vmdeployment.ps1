Param (
	[String] $Language = "en"
)

# __________________________________________________
#
# Setup
#
$Region = "dev"
$Description = "clean"
$VirtualMachineCount = 10

# __________________________________________________
#
# Deployment
#
.\Deployment.ps1 -Region $Region -Description $Description -Language $Language -VirtualMachineCount $VirtualMachineCount