Connect-VIServer -Server SERVERNAME
$key_project = 106
$key_contacts = 105
$key_role = 104
$key_pm = 107
$key_soft = 108
$num = 0
[array]$VMs=@()
foreach ($cluster in get-cluster)  {
    foreach ($vmview in (get-view -ViewType VirtualMachine -SearchRoot $cluster.id)) {
        $num += 1
        $vm=New-Object PsObject
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "№" -Value $num
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "Наименование" -Value $vmview.Name
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "Статус" -Value (Get-VM $vmview.Name | select PowerState).PowerState

        # Find certain attributes
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "Проект" -Value ($vmview.Summary.CustomValue | ? {$_.Key -eq 106}).value
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "Ответственный" -Value ($vmview.Summary.CustomValue | ? {$_.Key -eq 105}).value
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "Руководитель проекта" -Value ($vmview.Summary.CustomValue | ? {$_.Key -eq 107}).value
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "Основное ПО" -Value ($vmview.Summary.CustomValue | ? {$_.Key -eq 108}).value
        Add-Member -InputObject $vm -MemberType NoteProperty -Name "Назначение" -Value ($vmview.Summary.CustomValue | ? {$_.Key -eq 104}).value
        
        #Find all attributes
#       foreach ($CustomAttribute in $vmview.AvailableField){
#            Add-Member -InputObject $vm -MemberType NoteProperty -Name $CustomAttribute.Name -Value ($vmview.Summary.CustomValue | ? {$_.Key -eq $CustomAttribute.Key}).value
#        }
        $VMs+=$vm
    }
}
$VMs | Export-Csv d:\scripts\annotation-report.csv -NoType -UseCulture -Encoding UTF8
