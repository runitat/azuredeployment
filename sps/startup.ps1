# __________________________________________________
#
# Setup
#

# __________________________________________________
#
# Variables
#
$Computer = (Get-WmiObject Win32_ComputerSystem).Name
$Domain = (Get-WmiObject Win32_ComputerSystem).Domain

# __________________________________________________
#
# Add
#
function addDomUserToLocalGroup($group, $user) {
	$reference = [ADSI]"WinNT://$Computer/$group"
	$reference.Add("WinNT://$Domain/$user")
}

addDomUserToLocalGroup "Remote Desktop Users" "RDPUser"
addDomUserToLocalGroup "Administrators" "manager"
