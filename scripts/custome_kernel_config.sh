#!/bin/bash
# 一行命令：自动把 6.1 内核里所有支持的驱动全部设为 =m 模块
make -C kernel ARCH=arm64 allmodconfig
CONFIGS=(
  "CONFIG_NET_ACT_CT=m"
  "CONFIG_NET_ACT_CTINFO=m"
  "CONFIG_MALI_BIFROST=n"
  "CONFIG_MALI_MIDGARD=n"
  "CONFIG_MALI_VALHALL=n"
  "CONFIG_MALI_KBASE=n"
  "CONFIG_DRM=y"
  "CONFIG_DRM_KMS_HELPER=y"
  "CONFIG_DRM_ROCKCHIP=y"
  "CONFIG_DRM_PANFROST=y"
  "CONFIG_DRM_SCHED=y"
  "CONFIG_PM_DEVFREQ=y"
  "CONFIG_DEVFREQ_THERMAL=y"
)

source .current_config.mk
KCFG=kernel/arch/arm64/configs/$(awk '{print $1}' <<< "$TARGET_KERNEL_CONFIG")

for CFG in "${CONFIGS[@]}"; do
  KEY=${CFG%%=*}
  if grep -q "^#\?${KEY}=" "${KCFG}"; then
    sed -i "s@^#\?${KEY}=.*@${CFG}@g" "${KCFG}"
  else
    echo "$CFG" >> "${KCFG}"
  fi
done
