$pattern = ';'  
$content = Get-Content D:\vm.csv
Connect-VIServer -Server vm-vcenter
foreach ($line in $content){
	$item = $line.Split($pattern)
    $a = New-Object PSOBject -Property @{
		Num=$item[0]
		Name=$item[1]
		Project = $item[2]
		PMManager=$item[3]
		Role=$item[4]
		Contact=$item[5]
		Soft=$item[6]
	}
    Get-VM $a.Name | Set-Annotation	-CustomAttribute "Contact" -Value $a.Contact
	Get-VM $a.Name | Set-Annotation	-CustomAttribute "Project" -Value $a.Project
	Get-VM $a.Name | Set-Annotation	-CustomAttribute "PM Contact" -Value $a.PMManager
	Get-VM $a.Name | Set-Annotation	-CustomAttribute "Software" -Value $a.Soft
	Get-VM $a.Name | Set-Annotation	-CustomAttribute "VM Role" -Value $a.Role
	
}
