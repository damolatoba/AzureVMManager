function Install-OoRequiredModules {
	Install-Module -Name Az, Azure -Scope CurrentUser -Repository PSGallery -Force
}
	
function Connect-OoAzAccount {
	Connect-AzAccount
}

function Get-OoCountOfVM {
    Param (
		[Parameter(ParameterSetName = 'ResourceGroupList')]
		[String[]]$ResourceGroupList
    )
	
	PROCESS {
		$RGCount = $ResourceGroupList.Count
		if($RGCount -eq 0){
			Write-Progress -Activity "Counting total number of VMs in Subscription"
			$VMs = Get-AzVM
			$NumOfVM = $VMs.Count
			Write-Host "The total number of VMs in this Subscription is "$NumOfVM"."
		}
		else {
			$i = 1
			foreach ($RG in $ResourceGroupList){
				Write-Progress -Activity "Counting total number of VMs in Resource Group $RG" -Status "$i out of $RGCount Resource groups in progress"
				try {
					$VMs = Get-AzVM -ResourceGroupName $RG -ErrorAction Stop
					$NumOfVM = $VMs.Count
					Write-Host "Resource Group $RG has a total of $NumOfVM VMs."
				} catch {
					Write-Host "Resource Group $RG could not be found."
				} finally {}
				$i++
			}
		}
	}
}

function Get-OoStatusOfVM {
	Param (
		[Parameter()]
		[String[]]$ResourceGroupList,

		[Parameter()]
		[String[]]$VMList
    )

	PROCESS {
		if ($ResourceGroupList.Count -eq 1) {
			if($VMList.Count -eq 0){
				$VMs = Get-AzVM -ResourceGroupName $ResourceGroupList[0]
				foreach ($VM in $VMs) {
					$VMStatuses = Get-AzVM -ResourceGroupName $ResourceGroupList[0] -Name $VM.Name -Status | Select-Object -Property Name, Statuses
					Write-Host "The VM"$VMStatuses.Name"in Resouce Group"$ResourceGroupList[0]"status:"$VMStatuses.Statuses[1].DisplayStatus
				}
			} else {
				foreach ($VM in $VMList) {
					$VMStatuses = Get-AzVM -ResourceGroupName $ResourceGroupList[0] -Name $VM -Status | Select-Object -Property Name, Statuses
					Write-Host "The VM"$VMStatuses.Name"in Resouce Group"$ResourceGroupList[0]"status:"$VMStatuses.Statuses[1].DisplayStatus
				}
			}
		}

		if ($ResourceGroupList.Count -gt 1) {
			foreach ($RG in $ResourceGroupList) {
				$VMs = Get-AzVM -ResourceGroupName $RG
				foreach ($VM in $VMs) {
					$VMStatuses = Get-AzVM -ResourceGroupName $RG -Name $VM.Name -Status | Select-Object -Property Name, Statuses
					Write-Host "The VM"$VMStatuses.Name"in Resouce Group"$RG"status:"$VMStatuses.Statuses[1].DisplayStatus
				}
			}
		}

		if ($ResourceGroupList.Count -lt 1) {
			$ResourceGroups = Get-AzResourceGroup
			foreach ($RG in $ResourceGroups) {
				$VMs = Get-AzVM -ResourceGroupName $RG.ResourceGroupName
				foreach ($VM in $VMs) {
					$VMStatuses = Get-AzVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name -Status | Select-Object -Property Name, Statuses
					Write-Host "The VM"$VMStatuses.Name"in Resouce Group"$RG.ResourceGroupName"status:"$VMStatuses.Statuses[1].DisplayStatus ". `r`n"
				}
			}
		}
	}
}

function Start-OoStartVM {
	Param (
		[Parameter()]
		[String[]]$ResourceGroupList,

		[Parameter()]
		[String[]]$VMList
    )

	PROCESS {
		if (($ResourceGroupList.Count -eq 0) -and ($VMList.Count -eq 0)) {
			$RGList = Get-AzResourceGroup
			foreach ($RG in $RGList) {
				$VMs = Get-AzVM -ResourceGroupName $RG.ResourceGroupName
				foreach ($VM in $VMs) {
					Start-AzVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name
				}
			}
		} else {
			foreach ($RG in $ResourceGroupList) {
				$VMs = Get-AzVM -ResourceGroupName $RG
				foreach ($VM in $VMs) {
					Start-AzVM -ResourceGroupName $RG -Name $VM.Name
				}
			}
			foreach ($VM in $VMList) {
				$VMInfo = Get-AzVM -Name $VM
				if ($VMInfo.ResourceGroupName -notin $ResourceGroupList){
					Start-AzVM -ResourceGroupName $RG -Name $VMInfo.ResourceGroupName
				} else {
					Write-Host $VM"already in running state."
				}
			}
		}
	}
}

function Stop-OoStopVM {
	Param (
		[Parameter()]
		[String[]]$ResourceGroupList,

		[Parameter()]
		[String[]]$VMList
    )

	PROCESS {
		if (($ResourceGroupList.Count -eq 0) -and ($VMList.Count -eq 0)) {
			$RGList = Get-AzResourceGroup
			foreach ($RG in $RGList) {
				$VMs = Get-AzVM -ResourceGroupName $RG.ResourceGroupName
				foreach ($VM in $VMs) {
					Stop-AzVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name -Force
				}
			}
		} else {
			foreach ($RG in $ResourceGroupList) {
				$VMs = Get-AzVM -ResourceGroupName $RG
				foreach ($VM in $VMs) {
					Stop-AzVM -ResourceGroupName $RG -Name $VM.Name -Force
				}
			}
			foreach ($VM in $VMList) {
				$VMInfo = Get-AzVM -Name $VM
				if ($VMInfo.ResourceGroupName -notin $ResourceGroupList){
					Stop-AzVM -ResourceGroupName $VMInfo.ResourceGroupName -Name $VM -Force
				} else {
					Write-Host $VM"already in stopped state."
				}
			}
		}
	}
}