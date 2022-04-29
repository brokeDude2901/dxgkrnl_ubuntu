# dxgkrnl_linux

Use Linux on Hyper-V virtual machine with dxgrknl (GPU-P) support.

### Pros:
- More control, full Hyper-V virtual machine as your disposal.
- Has systemd.
### Cons:
- WSLg stuff is not supported. Use XRDP instead.
- Takes a lot of space. (Ubuntu 20.04 LTS Desktop 20G vs WSL2 500MB)
- No official support.
- Ubuntu 20.04 LTS installation takes long time.

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
ip a | grep eth0
```
- From Powershell of Windows Host:
```powershell
scp -r C:\Windows\System32\lxss\lib VM_USERNAME@VM_IP:temp_folder
scp -r C:\Windows\System32\DriverStore\FileRepository\nv_* VM_USERNAME@VM_IP:temp_folder/drivers
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
wget https://github.com/brokeDude2901/dxgkrnl_linux/releases/download/main/linux-headers-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb
wget https://github.com/brokeDude2901/dxgkrnl_linux/releases/download/main/linux-image-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb
sudo dpkg -i *.deb
```
- (Alternative) Build and install the kernel (~1 hour):
```bash
cd ~/
git clone https://github.com/microsoft/WSL2-Linux-Kernel.git
sudo apt-get install -y build-essential flex bison dwarves libssl-dev libelf-dev kernel-package libncurses5-dev fakeroot wget bzip2
cd WSL2-Linux-Kernel
wget https://raw.githubusercontent.com/brokeDude2901/dxgkrnl_linux/main/.config -O "./.config"
sudo make-kpkg -j$(nproc) --initrd kernel_image kernel_headers
cd ..
sudo dpkg -i *.deb
```
### 4. Reboot Ubuntu Hyper-V virtual machine:  
```bash
sudo reboot now
nvidia-smi
```
