COLOUR_GREEN=\n\033[0;32m
COLOUR_RED=\033[0;31m
COLOUR_BLUE=\033[0;34m
END_COLOUR=\033[0m\n

red:=$(shell tput setaf 1)
blue:=$(shell tput setaf 4)
reset:=$(shell tput sgr0)

BUILDDIR := /build/
BUILD_SOURCE_DIR := $(BUILDDIR)/build-source/

ifndef BOARD
$(error $(red)BOARD is not set$(reset))
endif

include /configs/settings.mk

ifneq ("$(wildcard /configs/$(BOARD)/settings.mk)","")
include /configs/$(BOARD)/settings.mk
else
$(error $(red)Board $(BOARD) not supported$(reset))
endif

include $(wildcard /builder/addons/*/addon.mk)

addon-targets = $(patsubst "%,$(BUILDDIR)/%-stamp,$(patsubst %",%,$(IMAGE_ADDITIONS)))
_PACKAGES = $(patsubst "%,%,$(patsubst %",%,$(PACKAGES)))


$(info $(blue)Board: $(BOARD)$(reset))
$(info $(blue)Storage: $(STORAGE_TYPE)$(reset))
$(info $(blue)Image Addons: $(IMAGE_ADDITIONS)$(reset))
$(info $(blue)Packages: $(_PACKAGES)$(reset))

NPROCS := $(shell nproc)


$(BUILDDIR)/linux-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out Kernel for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b sg200x-dev --depth 6 https://github.com/sophgo/linux_5.10.git /build/kernel
	@cd $(BUILDDIR)/kernel && git checkout 8b8fbf8
	@touch $@

$(BUILDDIR)/linux-prepare-patch-stamp: $(BUILDDIR)/linux-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Patching Kernel for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD)/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@cp /configs/$(BOARD)/linux/defconfig $(BUILDDIR)/kernel/arch/riscv/configs/${BOARD}_defconfig
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)/*), cp $(file) $(BUILDDIR)/kernel/arch/riscv/boot/dts/cvitek/;)
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)_$(ARCH)/*), cp $(file) $(BUILDDIR)/kernel/arch/riscv/boot/dts/cvitek/;)
	@$(foreach file, $(wildcard /configs/$(BOARD)/dts/*), cp $(file) $(BUILDDIR)/kernel/arch/riscv/boot/dts/cvitek/;)
	@python3 /builder/python/mmap_conv.py --type h /configs/$(BOARD)/memmap.py $(BUILDDIR)/kernel/arch/riscv/boot/dts/cvitek/cvi_board_memmap.h
	@touch $@

$(BUILDDIR)/linux-prepare-configure-stamp: $(BUILDDIR)/linux-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring Kernel for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/kernel KDEB_SOURCENAME=linux-sophgo  && $(MAKE) -j$(NPROCS) O=$(BUILDDIR)/kernel/ ARCH=riscv CROSS_COMPILE="/host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-" ${BOARD}_defconfig
	@$(eval LV=$(shell cd $(BUILDDIR)/kernel && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@sed -i 's/CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="$(LV)"/' $(BUILDDIR)/kernel/.config
	@touch $@

$(BUILDDIR)/linux-compile-stamp: $(BUILDDIR)/linux-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building Kernel for $(BOARD)$(END_COLOUR)"
	@sed -i 's/packagename=linux-image.*/packagename=linux-image-$(BOARD)/' $(BUILDDIR)/kernel/scripts/package/mkdebian
	@sed -i 's/packagename=linux-image-$$version/packagename=linux-image-$(BOARD)-$$version/' $(BUILDDIR)/kernel/scripts/package/builddeb
	@cd $(BUILDDIR)/kernel && KCFLAGS=-Wno-attribute-alias ARCH=riscv CROSS_COMPILE="/host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-" KDEB_SOURCENAME=linux-$(BOARD) $(MAKE) -j$(NPROCS) O=$(BUILDDIR)/kernel/ bindeb-pkg
	@cp $(BUILDDIR)/*.deb /output/
	@touch $@

linux: $(BUILDDIR)/linux-compile-stamp

linux-clean:
	@rm -rf $(BUILDDIR)/kernel
	@rm -f $(BUILDDIR)/linux-*-stamp
	@rm -f $(BUILDDIR)/linux-*.deb


$(BUILDDIR)/uboot-prepare-patch-stamp:
	@echo "$(COLOUR_GREEN)Patching U-Boot for $(BOARD)$(END_COLOUR)"
	# @$(foreach file, $(wildcard /configs/common/patches/u-boot/*.patch), cd $(BUILD_SOURCE_DIR)/u-boot-2021.10 && git apply --ignore-whitespace $(file);)
	# @$(foreach file, $(wildcard /configs/$(BOARD)/patches/u-boot/*.patch), cd $(BUILD_SOURCE_DIR)/u-boot-2021.10 && git apply --ignore-whitespace $(file);)
	@cp /configs/$(BOARD)/u-boot/defconfig $(BUILD_SOURCE_DIR)/u-boot-2021.10/configs/$(BOARD)_defconfig
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)/*), cp $(file) $(BUILD_SOURCE_DIR)/u-boot-2021.10/arch/riscv/dts/;)
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)_$(ARCH)/*), cp $(file) $(BUILD_SOURCE_DIR)/u-boot-2021.10/arch/riscv/dts/;)
	@$(foreach file, $(wildcard /configs/$(BOARD)/dts/*), cp $(file) $(BUILD_SOURCE_DIR)/u-boot-2021.10/arch/riscv/dts/;)
	@cp /configs/$(BOARD)/u-boot/cvitek.h $(BUILD_SOURCE_DIR)/u-boot-2021.10/include/cvitek.h
	@cp /configs/$(BOARD)/u-boot/cvi_board_init.c $(BUILD_SOURCE_DIR)/u-boot-2021.10/board/cvitek/cvi_board_init.c
	@python3 /builder/python/mmap_conv.py --type h /configs/$(BOARD)/memmap.py $(BUILD_SOURCE_DIR)/u-boot-2021.10/include/cvi_board_memmap.h
	@python3 /builder/python/mkcvipart.py /configs/$(BOARD)/$(PARTITION_FILE) $(BUILD_SOURCE_DIR)/u-boot-2021.10/include/
	@python3 /builder/python/mk_imgHeader.py /configs/$(BOARD)/$(PARTITION_FILE) $(BUILD_SOURCE_DIR)/u-boot-2021.10/include/ 
	@touch $@

$(BUILDDIR)/uboot-prepare-configure-stamp: $(BUILDDIR)/uboot-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring U-Boot for $(BOARD)$(END_COLOUR)"
	@cd $(BUILD_SOURCE_DIR)/u-boot-2021.10 && $(MAKE) -j$(NPROCS) BOARD=mars CONFIG_USE_DEFAULT_ENV=y STORAGE_TYPE=$(STORAGE_TYPE) CHIP=$(UBOOT_CHIP) CVIBOARD=$(UBOOT_BOARD) CROSS_COMPILE="/host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-" $(BOARD)_defconfig
	@touch $@

$(BUILDDIR)/uboot-compile-stamp: $(BUILDDIR)/uboot-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building U-Boot for $(BOARD)$(END_COLOUR)"
	@cd $(BUILD_SOURCE_DIR)/u-boot-2021.10/ && $(MAKE) -j$(NPROCS) BOARD=mars CONFIG_USE_DEFAULT_ENV=y STORAGE_TYPE=$(STORAGE_TYPE) CHIP=$(UBOOT_CHIP) CVIBOARD=$(UBOOT_BOARD) CROSS_COMPILE="/host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-"
	@cd $(BUILD_SOURCE_DIR)/u-boot-2021.10/ && $(MAKE) -j$(NPROCS) BOARD=mars CONFIG_USE_DEFAULT_ENV=y STORAGE_TYPE=$(STORAGE_TYPE) CHIP=$(UBOOT_CHIP) CVIBOARD=$(UBOOT_BOARD) CROSS_COMPILE="/host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-" u-boot-initial-env
	@cp $(BUILD_SOURCE_DIR)/u-boot-2021.10/u-boot.bin $(BUILD_SOURCE_DIR)
	@cp $(BUILD_SOURCE_DIR)/u-boot-2021.10/u-boot.dtb $(BUILD_SOURCE_DIR)
	@cp $(BUILD_SOURCE_DIR)/u-boot-2021.10/u-boot-initial-env $(BUILD_SOURCE_DIR)
	@touch $@

uboot: $(BUILDDIR)/uboot-compile-stamp


$(BUILDDIR)/opensbi-prepare-patch-stamp:
	@echo "$(COLOUR_GREEN)Patching OpenSBI for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/opensbi/*.patch), cd $(BUILD_SOURCE_DIR)/opensbi && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD)/patches/opensbi/*.patch), cd $(BUILD_SOURCE_DIR)/opensbi && git apply --ignore-whitespace $(file);)
	@touch $@

$(BUILDDIR)/opensbi-compile-stamp: $(BUILDDIR)/opensbi-prepare-patch-stamp $(BUILDDIR)/uboot-compile-stamp
	@echo "$(COLOUR_GREEN)Building OpenSBI for $(BOARD)$(END_COLOUR)"
	@cd $(BUILD_SOURCE_DIR)/opensbi && CROSS_COMPILE="/host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-" make PLATFORM=generic FW_FDT_PATH=$(BUILD_SOURCE_DIR)/u-boot.dtb
	@cp $(BUILD_SOURCE_DIR)/opensbi/build/platform/generic/firmware/fw_dynamic.bin $(BUILD_SOURCE_DIR)
	@touch $@

opensbi: $(BUILDDIR)/opensbi-compile-stamp


$(BUILDDIR)/fsbl-prepare-patch-stamp: $(BUILDDIR)/source-repo-checkout-stamp
	@echo "$(COLOUR_GREEN)Patching FSBL for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/fsbl/*.patch), cd $(BUILD_SOURCE_DIR)/fsbl && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD)/patches/fsbl/*.patch), cd $(BUILD_SOURCE_DIR)/fsbl && git apply --ignore-whitespace $(file);)
	@python3 /builder/python/mmap_conv.py --type h /configs/$(BOARD)/memmap.py $(BUILD_SOURCE_DIR)/fsbl/plat/$(CHIP)/include/cvi_board_memmap.h
	@printf '\163\000\120\020\157\360\337\377' > $(BUILD_SOURCE_DIR)/fsbl/blank.bin
	@touch $@

$(BUILDDIR)/fsbl-compile-stamp: $(BUILDDIR)/fsbl-prepare-patch-stamp $(BUILDDIR)/opensbi-compile-stamp $(BUILDDIR)/uboot-compile-stamp
	@echo "$(COLOUR_GREEN)Building FSBL for $(BOARD)$(END_COLOUR)"
	@cd $(BUILD_SOURCE_DIR)/fsbl && OD_CLK_SEL=y $(MAKE) -j$(NPROCS) ARCH=$(ARCH) CHIP_ARCH=$(CHIP) BOOT_CPU=$(BOOT_CPU) DDR_CFG=$(DDR_CFG) RTOS_ENABLE_FREERTOS=y BLCP_2ND_PATH=$(BUILD_SOURCE_DIR)/fsbl/blank.bin LOADER_2ND_PATH=$(BUILD_SOURCE_DIR)/u-boot.bin \
    CROSS_COMPILE=/host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl- 
	@cp $(BUILD_SOURCE_DIR)/fsbl/build/$(CHIP)/fip.bin $(BUILD_SOURCE_DIR)
	@touch $@

$(BUILDDIR)/fsbl-package-stamp: $(BUILDDIR)/fsbl-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging FSBL for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)
	@cp -r /builder/deb/cvitek-fsbl/* $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)/
	@mkdir -p $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)/boot/ $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)/etc/
	@cp $(BUILD_SOURCE_DIR)/fip.bin $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)/boot/
	@cp $(BUILD_SOURCE_DIR)/u-boot-initial-env $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)/etc/
	@sed -i 's/Version: 1.0.0/Version: $(FSBLVERSION)/' $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)/DEBIAN/control
	@sed -i 's/Package: cvitek-fsbl/Package: cvitek-fsbl-$(BOARD)/' $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION)/DEBIAN/control
	@cd $(BUILD_SOURCE_DIR)/package/ && dpkg-deb --build cvitek-fsbl-$(BOARD)-$(FSBLVERSION)
	@cp $(BUILD_SOURCE_DIR)/package/cvitek-fsbl-$(BOARD)-$(FSBLVERSION).deb /output/
	@touch $@

fsbl: $(BUILDDIR)/fsbl-package-stamp


$(BUILDDIR)/source-repo-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out main repo for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone --depth 1 https://github.com/sipeed/LicheeRV-Nano-Build.git $(BUILD_SOURCE_DIR)
	@cd $(BUILD_SOURCE_DIR) $$ git checkout a0dd574
	@touch $@

$(BUILDDIR)/image-prepare-stamp: 
	@echo "$(COLOUR_GREEN)Preparing Image for $(BOARD)$(END_COLOUR)"
	@-mkdir -p $(BUILDDIR)
	@rm -rf /rootfs/
	@-rm -f $(addon-targets)
	@mkdir -p /rootfs/
	@curl -L -s https://sophgo.my-ho.st:8443/public-key.asc -o $(BUILDDIR)/public-key.asc
	@apt-key add $(BUILDDIR)/public-key.asc
	@update-binfmts --enable qemu-riscv64
	@mmdebstrap -v --architectures=riscv64 --include="$(_PACKAGES)" sid "/rootfs/" "deb http://deb.debian.org/debian/ sid main" "deb https://sophgo.my-ho.st:8443/ debian sophgo"
	@touch $@

$(BUILDDIR)/image-addons-stamp: $(BUILDDIR)/image-prepare-stamp $(BUILDDIR)/fsbl-package-stamp $(BUILDDIR)/linux-compile-stamp $(addon-targets)
	@echo "$(COLOUR_GREEN)Copying Deb files for installation on $(BOARD)$(END_COLOUR)"
	@cp /output/cvitek-fsbl-$(BOARD)-*.deb /rootfs/tmp/install/ 
	@cp /output/linux-image-$(BOARD)-*.deb /rootfs/tmp/install/
	@cp /output/linux-headers-*.deb /rootfs/tmp/install/
	@cp /output/linux-libc-dev*.deb /rootfs/tmp/install/
	@touch $@


$(BUILDDIR)/image-customize-stamp: $(BUILDDIR)/image-addons-stamp $(BUILDDIR)/linux-compile-stamp $(BUILDDIR)/source-repo-checkout-stamp $(BUILDDIR)/fsbl-package-stamp
	@echo "$(COLOUR_GREEN)Customizing Image for $(BOARD)$(END_COLOUR)"
	@mkdir -p /rootfs/tmp/install/
	@echo $(BOARD) > /rootfs/tmp/install/hostname
	@echo $(BOARD) > /rootfs/tmp/install/board
	@echo $(STORAGE_TYPE) > /rootfs/tmp/install/storage
	@cp -v /usr/bin/qemu-riscv64-static /rootfs/tmp/install/
	@cp -v /builder/setup_rootfs.sh /rootfs/tmp/install/
	@cp -v $(BUILDDIR)/public-key.asc /rootfs/tmp/install/
	@chroot /rootfs/ /tmp/install/qemu-riscv64-static /bin/sh /tmp/install/setup_rootfs.sh
	@rm -rf /rootfs/tmp/install/
	@umount /rootfs/proc || true 
	@umount /rootfs/sys || true 
	@umount /rootfs/run || true 
	@umount /rootfs/dev || true
	@touch $@

$(BUILDDIR)/image-compile-stamp: $(BUILDDIR)/image-customize-stamp
	@echo "$(COLOUR_GREEN)Compiling Image for $(BOARD)$(END_COLOUR)"
	@rm -rf /tmp/genimage/
	@cd $(BUILDDIR) && genimage --config /builder/genimage_$(STORAGE_TYPE).cfg --tmppath /tmp/genimage --rootpath /rootfs/
	@rm -rf /tmp/genimage/
	@if [ "$(STORAGE_TYPE)" = "emmc" ]; then \
		python3 /builder/python/raw2cimg.py -v $(BUILDDIR)/images/sdcard.img $(BUILDDIR)/images /configs/$(BOARD)/partition_emmc.xml; \
		mkdir -p /tmp/rom/; \
		cp $(BUILDDIR)/images/sdcard.img /tmp/rom/; \
		cp /configs/$(BOARD)/partition_emmc.xml /tmp/rom/; \
		cp $(BUILDDIR)/fip.bin /tmp/rom/; \
		cd /tmp && zip $(BOARD)_$(STORAGE_TYPE).zip -r rom/; \
		cp /tmp/$(BOARD)_$(STORAGE_TYPE).zip /output/; \
		echo "$(COLOUR_GREEN)Image for $(BOARD) is $(BOARD)_$(STORAGE_TYPE).zip$(END_COLOUR)"; \
	else \
		cp $(BUILDDIR)/images/sdcard.img /output/$(BOARD)_$(STORAGE_TYPE).img; \
		echo "$(COLOUR_GREEN)Image for $(BOARD) is $(BOARD)_$(STORAGE_TYPE).img$(END_COLOUR)"; \
	fi 
	@touch $@

image: $(BUILDDIR)/image-compile-stamp

image-clean:
	@rm -rf /rootfs/
	@rm -f $(BUILDDIR)/image-*-stamp $(addon-targets)
	@rm -f /output/$(BOARD)_$(STORAGE_TYPE).img

image-clean-customize:
	@rm -f $(BUILDDIR)/image-customize-stamp

clean: opensbi-clean uboot-clean linux-clean fsbl-clean

.PHONY: image clean opensbi uboot linux fsbl fsbl-clean uboot-clean linux-clean opensbi-clean