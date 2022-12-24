$vcenter = "vCenterFQDN" # Your vCenter name -  vcenter.domain.local
$user = "username" # Your vCenter username - administrator@vsphere.local or domain\username
$password = "password" # Your vCenter password
$backupCategory = "Backup-Policy" # Your Backup Category that will be searched for virtual machines.
$noBackupTag = "NoBackup" # Your NoBackup Tag that will be searched for virtual machines.
$uriSlack = "https://..." # Your Slack URI
try {
    Disconnect-VIServer -server * -confirm:$false
}
catch {
    #"Could not find any of the servers specified by name."
}
$emoji = ':information_source: '
$text = ""
$vmNames = ""
$locationText = $emoji + "Location: HQ - Production vCenter" + "`n";

Connect-VIServer -Server $vcenter -User $user -Password $password | out-null
$noBackupTagVms = Get-VM | Where-Object { $_.Name -notlike "vCLS*" } | Get-TagAssignment -Category $backupCategory | Where-Object { $_.Tag.Name -eq $noBackupTag }

foreach ($vm in $noBackupTagVms) {
    $vmNames += $vm.Entity.Name + " > virtual machine is not protected because it is tagged with " + $noBackupTag + " tag." + "`n"
}

$noBackupPolicyVms = Get-VM | Where-Object { $_.Name -notlike "vCLS*" } | ? { (Get-TagAssignment $_ -Category $backupCategory) -eq $null }
foreach ($vm in $noBackupPolicyVms) {
    $vmNames += $vm.Name + " > virtual machine does not have any backup tag." + "`n"
}

if ($vmNames) {
    $text += $locationText + '```' + $vmNames + '```';
}

if ($text) {
    $baslik = $emoji + 'Unprotected Virtual Machines' + "`n";
    $action = $emoji + '*Action *: ' + "Check virtual machines if they need to be backed-up." + "`n" ;
    $body = ConvertTo-Json @{
        text = $baslik + $text + $action       
    }
    Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
}
#write-host $vmNames -ForegroundColor Cyan
Disconnect-VIServer -Server * -Confirm:$false | out-null 
