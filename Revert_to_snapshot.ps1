###################################################################
#
# RevertToSnapshot.ps1
# Version 1.0
# This script will log into your VMware environment, find and shutdown the virtual machine, and then convert it back to any snapshot you designate. 
# After that the script will turn the virtual machine back on.
####################################################################

### Global Settings ###
$vserver = "vm-vcenter.mdi.ru" #Add VMWare server
$vmname = "vm-085-phoenix.mdi.ru" #Add virtual machine
$snapshotsname = "Reference"#Add Snapshot

Connect-VIServer -Server $vserver

### Power Functions ###
function PowerOff-VM{
param([string] $vm)
if((Get-VM $vm).powerstate -eq "PoweredOff"){
Write-Host "$vm is already powered off"}
else{
Shutdown-VMGuest -VM (Get-VM $vm) -Confirm:$false | Out-Null
Write-Host "Shutdown $vm"
do {
$status = (get-VM $vm).PowerState
}until($status -eq "PoweredOff")
}
}

function PowerOn-VM{
param( [string] $vm)
if((Get-VM $vm).powerstate -eq "PoweredOn"){
Write-Host "$vm is already powered on"}
else{
Start-VM -VM (Get-VM $vm) -Confirm:$false | Out-Null
Write-Host "Starting $vm"
do {
$status = (Get-vm $vm | Get-View).Guest.ToolsRunningStatus
}until($status -eq "guestToolsRunning")
}
}

### Main script ###
$poweroff = PowerOff-VM $vmname

# Set Snapshot name
$snapname = Get-Snapshot -VM (Get-VM -Name $vmname) -Name $snapshotsname

# Set VM to snapshot
Set-VM -VM $vmname -Snapshot $snapname -confirm:$false

$poweron = PowerOn-VM $vmname

Disconnect-VIServer -Server $vserver -confirm:$false
