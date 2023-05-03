#Connect Azure account
Connect-AzAccount

$rgname = 'WTH-Hub-Spoke-Networking-EM'
$location = 'uksouth'
New-AzResourceGroup -Name $rgname -Location uksouth

#hub vnet and subnet, gateway subnet, and firewall subnet
New-AzVirtualNetwork -ResourceGroupName $rgname -Name hubVNet -Location $location -AddressPrefix 10.0.0.0/16
$hubvnet = Get-AzVirtualNetwork -Name hubVNet -ResourceGroupName $rgname
Add-AzVirtualNetworkSubnetConfig -Name hubVMsubnet -VirtualNetwork $hubvnet -AddressPrefix 10.0.10.0/24
Add-AzVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $hubvnet -AddressPrefix 10.0.0.0/24
Add-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -VirtualNetwork $hubvnet -AddressPrefix 10.0.1.0/24

#spoke 1 vnet and subnet
New-AzVirtualNetwork -ResourceGroupName $rgname -Name spoke1VNet -Location $location -AddressPrefix 10.1.0.0/16
$spoke1vnet = Get-AzVirtualNetwork -Name spoke1VNet -ResourceGroupName $rgname
Add-AzVirtualNetworkSubnetConfig -Name spoke1VMsubnet -VirtualNetwork $spoke1vnet -AddressPrefix 10.1.10.0/24

#spoke 2 svnet and subnet
New-AzVirtualNetwork -ResourceGroupName $rgname -Name spoke2VNet -Location $location -AddressPrefix 10.2.0.0/16
$spoke2vnet = Get-AzVirtualNetwork -Name spoke2VNet -ResourceGroupName $rgname
Add-AzVirtualNetworkSubnetConfig -Name spoke2VMsubnet -VirtualNetwork $spoke2vnet -AddressPrefix 10.2.10.0/24

#
# Create Azure credentials for HubVM

#Create hubVM and install IIS
$hubVMadminCredential = Get-Credential -Message "Enter a username and password for the VM administrator"
$hubvmName = 'HubVM'
$hubvmpublicIpAddressName = "myPublicIpAddress1"
New-AzVm 
    -ResourceGroupName $rgname 
    -Name $hubvmName 
    -Credential $hubVMadminCredential 
    -Location $location
    -VirtualNetworkName "hubVNet"
    -SubnetName "hubVMsubnet"
    -PublicIpAddressName $hubvmpublicIpAddressName
    -OpenPorts 3389, 80
Invoke-AzVMRunCommand 
    -ResourceGroupName $rgname 
    -VMName $hubvmName 
    -CommandId 'RunPowerShellScript' 
    -ScriptString 'Install-WindowsFeature -Name Web-Server -IncludeManagementTools'
    
#Create spoke1VM and install IIS
$spoke1VMadminCredential = Get-Credential -Message "Enter a username and password for the VM administrator"
$spoke1vmName = 'Spoke1VM'
$spoke1vmpublicIpAddressName = "myPublicIpAddress2"
New-AzVm 
    -ResourceGroupName $rgname 
    -Name $spoke1vmName 
    -Credential $spoke1VMadminCredential 
    -Location $location
    -VirtualNetworkName "spoke1VNet"
    -SubnetName "spoke1VMsubnet"
    -PublicIpAddressName $spoke1vmpublicIpAddressName
    -OpenPorts 3389, 80
Invoke-AzVMRunCommand 
    -ResourceGroupName $rgname 
    -VMName $spoke1vmName 
    -CommandId 'RunPowerShellScript' 
    -ScriptString 'Install-WindowsFeature -Name Web-Server -IncludeManagementTools'
    

#Create spoke2VM and install IIS
$spoke2VMadminCredential = Get-Credential -Message "Enter a username and password for the VM administrator"
$spoke2vmName = 'spoke2VM'
$spoke2vmpublicIpAddressName = "myPublicIpAddress3"
New-AzVm 
    -ResourceGroupName $rgname 
    -Name $spoke2vmName 
    -Credential $spoke2VMadminCredential 
    -Location $location
    -VirtualNetworkName "spoke2VNet"
    -SubnetName "spoke2VMsubnet"
    -PublicIpAddressName $spoke2vmpublicIpAddressName
    -OpenPorts 3389, 80
Invoke-AzVMRunCommand 
    -ResourceGroupName $rgname 
    -VMName $spoke2vmName 
    -CommandId 'RunPowerShellScript' 
    -ScriptString 'Install-WindowsFeature -Name Web-Server -IncludeManagementTools'
    

# Verify success by checking for VMs
Get-AzResource -ResourceType Microsoft.Compute/virtualMachines

## Place the virtual network hubVNet configuration into a variable. ##
$hubVNet = Get-AzVirtualNetwork -Name hubVNet -ResourceGroupName $rgname
## Place the virtual network spoke1vnet configuration into a variable. ##
$spoke1vnet = Get-AzVirtualNetwork -Name spoke1VNet -ResourceGroupName $rgname
## Place the virtual network spoke2vnet configuration into a variable. ##
$spoke2vnet = Get-AzVirtualNetwork -Name spoke2VNet -ResourceGroupName $rgname
## Create peering from hubVNet to spoke1VNet. ##
Add-AzVirtualNetworkPeering -Name hubVNet-to-spoke1VNet -VirtualNetwork $hubVNet -RemoteVirtualNetworkId $spoke1VNet.Id -AllowGatewayTransit 
## Create peering from spoke1VNet to hubVNet. ##
Add-AzVirtualNetworkPeering -Name spoke1VNet-to-hubVNet -VirtualNetwork $spoke1VNet -RemoteVirtualNetworkId $hubVNet.Id -UseRemoteGateways
## Create peering from hubVNet to spoke2VNet. ##
Add-AzVirtualNetworkPeering -Name hubVNet-to-spoke2VNet -VirtualNetwork $hubVNet -RemoteVirtualNetworkId $spoke2VNet.Id -AllowGatewayTransit 
## Create peering from spoke2VNet to hubVNet. ##
Add-AzVirtualNetworkPeering -Name spoke2VNet-to-hubVNet -VirtualNetwork $spoke2VNet -RemoteVirtualNetworkId $hubVNet.Id -UseRemoteGateways


#create simulated on-prem vnet, subnet, and gateway subnet 
New-AzVirtualNetwork -ResourceGroupName $rgname -Name onpremVNet -Location $location -AddressPrefix 172.16.0.0/16
$onpremvnet = Get-AzVirtualNetwork -Name onpremVNet -ResourceGroupName $rgname
Add-AzVirtualNetworkSubnetConfig -Name onpremSubnet -VirtualNetwork $onpremvnet -AddressPrefix 172.16.10.0/24
Add-AzVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $onpremvnet -AddressPrefix 172.16.0.0/24

#Create onprem VM
$onpremVMadminCredential = Get-Credential -Message "Enter a username and password for the VM administrator"
$onpremvmName = 'onpremVM'
$onpremvmpublicIpAddressName = "myPublicIpAddress4"
New-AzVm 
    -ResourceGroupName $rgname 
    -Name $onpremvmName 
    -Credential $onpremVMadminCredential 
    -Location $location
    -VirtualNetworkName "onpremVNet"
    -SubnetName "onpremSubnet"
    -PublicIpAddressName $onpremvmpublicIpAddressName
    -OpenPorts 3389


#create pblic ip addresses in both gateway subnets

#create vnet gateway 

#create local network gateways in both gateway subnets

#create vpn connections