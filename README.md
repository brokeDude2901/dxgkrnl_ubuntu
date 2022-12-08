<img width="770" alt="image" src="https://user-images.githubusercontent.com/46110534/202920205-2add7533-ac42-43d6-8d16-b083deca51a0.png">
<img width="770" alt="image" src="https://user-images.githubusercontent.com/46110534/202920235-e84d1811-c770-4b3a-aff2-55581bd2e5a6.png">


# dxgkrnl_ubuntu
Use Ubuntu on Hyper-V VM with Microsoft GPU-P support (dxgrknl kernel).

### Windows Host Requirement:
- Windows 10 21H1 or later 
- Windows 11 (all builds)
- Windows Server 2022 Insider Preview Build 25246 (havent test older builds)

### Pros:
- Full Hyper-V VM with more features than WSL2 (systemd, snap package, Hyper-V External Network, ...)
- Can have one real GPU sharable among multiple Hyper-V VMs
- Can use Moonlight / Sunshine Host to have 3D accelerated Remote Desktop 
### Cons:
- Any Docker CUDA image built inside this VM, will not work with bare metal machine (libcuda.so problems, NVIDIA side)
- Only tested on Ubuntu 20.04 / 22.04
- Current kernel 5.10 need to be updated to the WSL2 5.15 Kernel :(
- Should work with AMD too, but I don't have AMD cards to test

# Instructions
### 1. Create a Gen 2 Hyper-V virtual machine, install Ubuntu 20.04 LTS / 22.04 LTS as normal 

### 2. Attach GPU-P adapter to your Ubuntu VM
- From Windows Host, run Powershell as Administrator
```powershell
# change ubuntu to your current vm name
$vm = "ubuntu"

# this will remove any current gpu-p adapter then reattach them all
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
- For Windows Server 2022 Insider Preview need to do this:
```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HyperV" -Name "RequireSecureDeviceAssignment" -Type DWORD -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HyperV" -Name "RequireSupportedDeviceAssignment" -Type DWORD -Value 0 -Force
```
### 3. Copy Windows Host GPU Driver to Ubuntu VM:
- From Ubuntu VM:
```bash
# enable SSH
sudo apt-get update && sudo apt-get install -y openssh-server 
# note down current VM ip
ip a | grep eth0  
# prepare temp_folder
mkdir -p $HOME/temp_folder/lib && mkdir -p $HOME/temp_folder/drivers 
```
- From Windows Host, run Powershell as Administrator
```powershell
# get currentdriverfolder from this result
Get-CimInstance -ClassName Win32_VideoController -Property *
```
<img width="1440" alt="image" src="https://user-images.githubusercontent.com/46110534/202920319-d69d9071-bf3b-41e1-957b-4b695b8c0fa7.png">

```powershell
# define your vmip, vmusername and currentdriverfolder
$vmip = "192.168.1.106"
$vmusername = "abcdefg"
$currentdriverfolder = "C:\Windows\System32\DriverStore\FileRepository\nvhdcig.inf_amd64_26476eaed29e569c"

# Use scp to copy Windows Host drivers to Ubuntu VM
scp -r C:\Windows\System32\lxss\lib "${vmusername}@${vmip}:temp_folder"
scp -r $currentdriverfolder "${vmusername}@${vmip}:temp_folder/drivers"
```
- From Ubuntu VM:
```bash
sudo rm -rf /usr/lib/wsl && 
sudo mkdir -p /usr/lib/wsl/lib && 
sudo cp -r $HOME/temp_folder/* /usr/lib/wsl && 
sudo chmod 555 /usr/lib/wsl/lib/* && 
sudo chown -R root:root /usr/lib/wsl && 
echo "/usr/lib/wsl/lib" | sudo tee /etc/ld.so.conf.d/ld.wsl.conf && 
sudo ldconfig && 
echo "export PATH=$PATH:/usr/lib/wsl/lib" | sudo tee /etc/profile.d/wsl.sh && 
sudo chmod +x /etc/profile.d/wsl.sh
```
- Repeat this step 3 if you update your current Windows Host Driver
### 4. Install custom dxgkrnl kernel:
- From Ubuntu VM:
```bash
# Download and install dxgrknl kernel
wget https://github.com/brokeDude2901/dxgkrnl_ubuntu/releases/download/main/linux-headers-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb && 
wget https://github.com/brokeDude2901/dxgkrnl_ubuntu/releases/download/main/linux-image-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb && 
sudo dpkg -i ./linux-headers-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb && 
sudo dpkg -i ./linux-image-5.10.102.1-dxgrknl_5.10.102.1-dxgrknl-10.00.Custom_amd64.deb

# Make GRUB show menu for you to choose the installed dxgkrnl
sudo sed -i "s/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/g" /etc/default/grub && 
sudo sed -i "s/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/g" /etc/default/grub && 
sudo sed -i "s/GRUB_TIMEOUT=0/GRUB_TIMEOUT=30/g" /etc/default/grub && 
sudo grep -q -F "GRUB_SAVEDEFAULT=true" /etc/default/grub || echo "GRUB_SAVEDEFAULT=true" | sudo tee -a /etc/default/grub && 
sudo update-grub && cat /etc/default/grub
```
### 5. Reboot Ubuntu VM, select the new dxgkrnl kernel, enjoy !  
<img width="770" alt="image" src="https://user-images.githubusercontent.com/46110534/202920514-c3fdbc87-0a0d-4923-b575-df14b0d0fe8a.png">

### 6. (OPTIONAL) Install nvidia-docker: 
```bash
sudo apt-get update && 
sudo apt-get install -y curl &&
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - &&
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu18.04/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list &&
sudo apt-get update && sudo apt install -y nvidia-docker2
```
- Perform a quick Docker test see if GPU is working
```bash
sudo docker run --rm --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark && 
sudo docker run --rm -it -v /usr/lib/wsl/lib/nvidia-smi:/usr/local/bin/nvidia-smi --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```
<img width="1440" alt="image" src="https://user-images.githubusercontent.com/46110534/202920127-007fe4d9-e20b-4b49-b4cd-c2f95c81f89d.png">

### 7. (OPTIONAL) Use Hyper-V Core scheduler to avoid bugs:
- By default Windows 11 use Root scheduler, which sometimes buggy, cause extremely high CPU usage
- From Windows Host, run Powershell as Administrator
```powershell
bcdedit /set hypervisorschedulertype Core
```
- Reboot to have effect, see article here: https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-scheduler-types
### 8. (EXPERIMENTAL) Use Moonlight / Sunshine Host for smooth remote desktop and gaming (tested on NVENC H264 and HEVC)
- Setup Sunshine Host on Ubuntu VM:
```bash
wget https://github.com/LizardByte/Sunshine/releases/download/v0.15.0/sunshine.deb && sudo apt-get install ./sunshine.deb
# fix libssl for ubuntu 22.04
echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list
sudo apt-get update && sudo apt-get install libssl1.1
# finally run this inside Hyper-V window (bc it has an active WAYLAND session) not on SSH
sudo mkdir -p /dev/dri && sudo mkdir -p /root/.config/sunshine & sudo sunshine
# open URL to config your Sunshine Host password, later accept the right PIN code from Moonlight client
```
- Setup Moonlight on Windows Host from: https://moonlight-stream.org/, set the resolution to 1024x768 and Windowed Mode

GPU Encode & Decode Engine working :)
![image](https://user-images.githubusercontent.com/46110534/206408231-18c8e4bc-ffb2-4a80-808d-fe6e30d842bb.png)
![image](https://user-images.githubusercontent.com/46110534/206409166-6206cd6f-57fc-4f99-b958-4c735372b9b9.png)

