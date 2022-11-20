# notice: 
- this is outdated for Ubuntu 22.04, WSL2 now use kernel 5.15
# plans: 
- Provide instruction to build the dxgkrnl kernel (both 5.10 and 5.15)
- AMD guide
- Wayland XRDP with GPU acceleration (similar to WSLg)

# dxgkrnl_ubuntu
Use Ubuntu on Hyper-V virtual machine with dxgrknl (GPU-P) support.

### Pros:
- Full Hyper-V virtual machine as your disposal.
- Has systemd.
### Cons:
- WSLg stuff is not supported. Use XRDP (without GPU acceleration) instead.

![image](https://user-images.githubusercontent.com/46110534/164886442-d4977e78-5748-40b3-aab1-e3b25a15866f.png)

# Instructions

### 1. Enable GPU-P for your Hyper-V virtual machine:
- Create a Gen 2 Hyper-V virtual machine, install Ubuntu 20.04 LTS as normal 
- From Windows Host run Powershell as Administrator (change "ubuntu" to your actual Hyper-V virtual machine name):
```powershell
$vm = "ubuntu"
Remove-VMGpuPartitionAdapter -VMName $vm
$gpu_list = Get-VMHostPartitionableGpu
foreach ($k in $gpu_list){
    $instance_path = $k.Name
    $instance_path
    Add-VMGpuPartitionAdapter -VMName $vm -InstancePath $instance_path
}
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionVRAM 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionVRAM 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionVRAM 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionEncode 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionEncode 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionEncode 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionDecode 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionDecode 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionDecode 10
Set-VMGpuPartitionAdapter -VMName $vm -MinPartitionCompute 1
Set-VMGpuPartitionAdapter -VMName $vm -MaxPartitionCompute 11
Set-VMGpuPartitionAdapter -VMName $vm -OptimalPartitionCompute 10
Set-VM -GuestControlledCacheTypes $true -VMName $vm
Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $vm
Set-VM -HighMemoryMappedIoSpace 32GB -VMName $vm
```
### 2. Prepare /usr/lib/wsl:  

- From Ubuntu Hyper-V virtual machine: 
```bash
sudo apt-get update && sudo apt-get install -y openssh-server
mkdir -p $HOME/temp_folder/lib
mkdir -p $HOME/temp_folder/drivers
```
```
ip a | grep eth0
```
- From Powershell of Windows Host:
```powershell
$vmip = "192.168.1.106" # get this from your previous result
$vmusername = "abcdefg" # get this from your previous result
scp -r C:\Windows\System32\lxss\lib $vmusername@$vmip:temp_folder
scp -r C:\Windows\System32\DriverStore\FileRepository\nv_* $vmusername@$vmip:temp_folder/drivers
```
- From Ubuntu Hyper-V virtual machine: 
```bash
sudo rm -rf /usr/lib/wsl
sudo mv $HOME/temp_folder /usr/lib/wsl
sudo chmod 555 /usr/lib/wsl/lib/*
sudo chown -R root:root /usr/lib/wsl
sudo bash -c 'echo "/usr/lib/wsl/lib" > /etc/ld.so.conf.d/ld.wsl.conf'
sudo ldconfig
sudo bash -c 'echo export PATH=$PATH:/usr/lib/wsl/lib > /etc/profile.d/wsl.sh'
sudo chmod +x /etc/profile.d/wsl.sh
```
### 3. Install the kernel:
- Download and install the .deb package:
```bash
cd ~/
wget https://github.com/brokeDude2901/dxgkrnl_ubuntu/releases/download/main/linux-headers-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb
wget https://github.com/brokeDude2901/dxgkrnl_ubuntu/releases/download/main/linux-image-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb
sudo dpkg -i *.deb
```
- To be able to select dxgkrnl in grub:
```bash
sudo nano /etc/default/grub
```
```text
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
```
```bash
sudo update-grub
```

### 4. Reboot Ubuntu Hyper-V virtual machine:  
```bash
sudo reboot now
nvidia-smi
```
### 5. Install nvidia-docker: 
```bash
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu18.04/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt install nvidia-docker2
```
you might need to copy /usr/lib/nvidia-smi to /usr/bin/nvidia-smi to have nvidia-smi mounted in your container
