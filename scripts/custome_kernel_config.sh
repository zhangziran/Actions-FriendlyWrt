#!/bin/bash

# 定义需要禁用和开启的内核选项
CONFIGS=(
  # 1. 禁用原厂闭源 Mali 驱动 (mali_kbase)
  "CONFIG_MALI_BIFROST=n"
  "CONFIG_MALI_MIDGARD=n"
  "CONFIG_MALI_VALHALL=n"
  "CONFIG_MALI_KBASE=n"

  # 2. 启用开源 Panfrost 驱动及相关依赖
  "CONFIG_DRM=y"
  "CONFIG_DRM_KMS_HELPER=y"
  "CONFIG_DRM_ROCKCHIP=y"
  "CONFIG_DRM_PANFROST=y"
  "CONFIG_DRM_SCHED=y"
  "CONFIG_PM_DEVFREQ=y"
  "CONFIG_DEVFREQ_THERMAL=y"
)

# 读取当前编译目标对应的内核配置文件路径
if [ -f .current_config.mk ]; then
  source .current_config.mk
  KCFG=kernel/arch/arm64/configs/$(awk '{print $1}' <<< "$TARGET_KERNEL_CONFIG")

  # 如果找到了目标配置文件，进行精准替换与追加
  if [ -f "${KCFG}" ]; then
    echo "Updating kernel config: ${KCFG}"
    for CFG in "${CONFIGS[@]}"; do
      KEY=${CFG%%=*}
      if grep -q "^#\?${KEY}[ =]" "${KCFG}"; then
        sed -i "s@^#\?${KEY}[ =].*@${CFG}@g" "${KCFG}"
      else
        echo "$CFG" >> "${KCFG}"
      fi
    done
  fi
fi
