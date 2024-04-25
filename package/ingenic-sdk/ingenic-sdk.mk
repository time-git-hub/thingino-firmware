INGENIC_SDK_SITE_METHOD = git
INGENIC_SDK_SITE = https://github.com/themactep/ingenic-sdk
INGENIC_SDK_VERSION = $(shell git ls-remote $(INGENIC_SDK_SITE) master | head -1 | cut -f1)

INGENIC_SDK_LICENSE = GPL-3.0
INGENIC_SDK_LICENSE_FILES = LICENSE

INGENIC_SDK_MODULE_MAKE_OPTS = \
	SOC_FAMILY=$(SOC_FAMILY) \
	SENSOR_MODEL=$(SENSOR_MODEL) \
	KERNEL_VERSION=$(KERNEL_VERSION) \
	INSTALL_MOD_PATH=$(TARGET_DIR) \
	INSTALL_MOD_DIR=ingenic

LINUX_CONFIG_LOCALVERSION = \
	$(shell awk -F "=" '/^CONFIG_LOCALVERSION=/ {print $$2}' $(BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE))

ifeq ($(BR2_SOC_INGENIC_T10)$(BR2_SOC_INGENIC_T20)$(BR2_SOC_INGENIC_T30),y)
SENSOR_CONFIG_NAME = $(SENSOR_MODEL).bin
else
SENSOR_CONFIG_NAME = $(SENSOR_MODEL)-$(SOC_FAMILY).bin
endif

ifeq ($(KERNEL_VERSION_4),y)
FULL_KERNEL_VERSION = 4.4.94
else
FULL_KERNEL_VERSION = 3.10.14
endif

define INGENIC_SDK_BUILD_CMDS
		$(INGENIC_SDK_PKGDIR)/module.sh $(SENSOR_MODEL) $(SOC_FAMILY) > $(@D)/sensor_params.conf
endef

define INGENIC_SDK_INSTALL_TARGET_CMDS
	$(INSTALL) -m 755 -d $(TARGET_DIR)/lib/modules/$(FULL_KERNEL_VERSION)$(call qstrip,$(LINUX_CONFIG_LOCALVERSION))
	touch $(TARGET_DIR)/lib/modules/$(FULL_KERNEL_VERSION)$(call qstrip,$(LINUX_CONFIG_LOCALVERSION))/modules.builtin.modinfo

	$(INSTALL) -m 755 -d $(TARGET_DIR)/etc/sensor
	$(INSTALL) -m 644 -D $(@D)/sensor-iq/$(SOC_FAMILY)/$(SENSOR_MODEL).bin $(TARGET_DIR)/etc/sensor/$(SENSOR_CONFIG_NAME)
	echo $(SENSOR_MODEL) >$(TARGET_DIR)/etc/sensor/model

	$(INSTALL) -m 755 -d $(TARGET_DIR)/etc/modules.d
	$(INSTALL) -m 644 $(@D)/sensor_params.conf $(TARGET_DIR)/etc/modules.d/sensor

	echo tx_isp_$(SOC_FAMILY) isp_clk=$(ISP_CLK) $(ISP_MEMOPT) $(ISP_DAY_NIGHT_SWITCH_DROP_FRAME_NUM) $(ISP_CH0_PRE_DEQUEUE_TIME) $(ISP_CH0_PRE_DEQUEUE_INTERRUPT_PROCESS) $(ISP_CH0_PRE_DEQUEUE_VALID_LINES) > $(TARGET_DIR)/etc/modules.d/isp
	if [ "$$SOC_FAMILY" = "t31" ]; then \
		echo "avpu $(AVPU_CLK_SRC) avpu_clk=$(AVPU_CLK)" > $(TARGET_DIR)/etc/modules.d/avpu; \
	fi
endef

$(eval $(kernel-module))
$(eval $(generic-package))
