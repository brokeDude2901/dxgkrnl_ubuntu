#!/usr/bin/bash

array=("arch/arm64/hyperv/Makefile" \
"arch/arm64/hyperv/hv_core.c" \
"arch/arm64/hyperv/hv_hvc.S" \
"arch/arm64/hyperv/hv_pci_vector.c" \
"arch/arm64/hyperv/mshyperv.c" \
"drivers/hv/dxgkrnl/Kconfig" \
"drivers/hv/dxgkrnl/Makefile" \
"drivers/hv/dxgkrnl/dxgadapter.c" \
"drivers/hv/dxgkrnl/dxgkrnl.h" \
"drivers/hv/dxgkrnl/dxgmodule.c" \
"drivers/hv/dxgkrnl/dxgprocess.c" \
"drivers/hv/dxgkrnl/dxgsyncfile.c" \
"drivers/hv/dxgkrnl/dxgsyncfile.h" \
"drivers/hv/dxgkrnl/dxgvmbus.c" \
"drivers/hv/dxgkrnl/dxgvmbus.h" \
"drivers/hv/dxgkrnl/hmgr.c" \
"drivers/hv/dxgkrnl/hmgr.h" \
"drivers/hv/dxgkrnl/misc.c" \
"drivers/hv/dxgkrnl/misc.h" \
"Microsoft/config-wsl" \
"Microsoft/config-wsl-arm64" \
"arch/arm64/include/asm/hyperv-tlfs.h" \
"arch/arm64/include/asm/mshyperv.h"
"arch/arm64/include/asm/apicdef.h"
"drivers/hv/hv_common.c" \
"include/uapi/misc/d3dkmthk.h" \
"arch/arm64/include/asm/pci.h" \
"arch/arm64/Kbuild" \
"arch/arm64/kernel/efi.c" \
"arch/arm64/kernel/pci.c" \
"arch/arm64/kernel/setup.c" \
"arch/x86/hyperv/hv_init.c" \
"arch/x86/include/asm/hyperv-tlfs.h" \
"arch/x86/include/asm/mshyperv.h" \
"arch/x86/kernel/cpu/mshyperv.c" \
"drivers/clocksource/hyperv_timer.c" \
"drivers/hv/hv_balloon.c" \
"drivers/hv/hv.c" \
"drivers/hv/Kconfig" \
"drivers/hv/Makefile" \
"drivers/hv/vmbus_drv.c" \
"drivers/irqchip/irq-gic-v3.c" \
"drivers/Makefile" \
"drivers/nvdimm/virtio_pmem.c" \
"drivers/nvdimm/virtio_pmem.h" \
"drivers/pci/controller/Kconfig" \
"drivers/pci/controller/pci-hyperv.c" \
"drivers/pci/Kconfig" \
"include/asm-generic/hyperv-tlfs.h" \
"include/asm-generic/mshyperv.h" \
"include/clocksource/hyperv_timer.h" \
"include/linux/arm-smccc.h" \
"include/linux/hyperv.h" \
"include/linux/pci.h")

WORKDIR=~/linux-5.17
cd $WORKDIR

mkdir -p ./Microsoft
mkdir -p ./drivers/hv/dxgkrnl
mkdir -p ./arch/arm64/hyperv

for object in ${array[@]}; do
  wget "https://raw.githubusercontent.com/microsoft/WSL2-Linux-Kernel/linux-msft-wsl-5.10.y/$object" --output-document="./$object"
done
