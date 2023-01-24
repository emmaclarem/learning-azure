# Import Azure PowerShell module
Import-Module -Name Az

# Connect to an Azure account
Connect-AzAccount

# Define Azure variables for a virtual machine 
$resourceGroup = "myResourceGroup"
$location = "EastUS"

# Create Azure credentials
$adminCredential = Get-Credential -Message "Enter a username and password for the VM administrator"

#Create three virtual machines in Azure
For ($i = 1; $i -le 3; $i++)
{
    $vmName = "demo-vm" + $i
    $publicIpAddressName = "myPublicIpAddress" + $i
    Write-Host "Creating VM: " $vmName
    New-AzVm 
        -ResourceGroupName $resourceGroup 
        -Name $vmName 
        -Credential $adminCredential 
        -Location $location
        -VirtualNetworkName "myVnet"
        -SubnetName "mySubnet"
        -SecurityGroupName "myNetworkSecurityGroup"
        -PublicIpAddressName $publicIpAddressName
        -OpenPorts 80,3389
}

# Verify success by checking for VMs
Get-AzResource -ResourceType Microsoft.Compute/virtualMachines

# Clean up resource group afterwards, if desired
# Remove-AzResourceGroup -Name "myResourceGroup"