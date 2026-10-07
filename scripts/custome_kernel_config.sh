#!/bin/bash

# =========================================================
# NanoPi M5 (RK3576) 6.1 厂商内核智能驱动注入脚本
# 规则：
# 1. 显卡冲突驱动强制设为 =n (保护 Panfrost)
# 2. 如果原厂配置已经是 =y (内置)，【绝对不降级】，直接保留 =y！
# 3. 如果原厂配置缺失或未开启，【安全补全】为 =m 模块
# =========================================================

CONFIGS=(
  # --- 1. Panfrost 开源显卡与 DRM 配置 (互斥驱动必须强制 =n) ---
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

  # --- 4. 全量 USB 有线网卡 (Realtek 2.5G/千兆, Asix 亚信, 5G/4G 拨号) ---
  "CONFIG_USB_NET_DRIVERS=m"
  "CONFIG_USB_RTL8152=m"
  "CONFIG_USB_RTL8150=m"
  "CONFIG_USB_NET_AX88179_178A=m"
  "CONFIG_USB_NET_AX8817X=m"
  "CONFIG_USB_NET_CDCETHER=m"
  "CONFIG_USB_NET_CDC_NCM=m"
  "CONFIG_USB_NET_HUAWEI_CDC_NCM=m"
  "CONFIG_USB_NET_CDC_MBIM=m"
  "CONFIG_USB_NET_QMI_WWAN=m"
  "CONFIG_USB_NET_RNDIS_HOST=m"

  # --- 5. 全量 Wi-Fi 无线网卡 ---
  "CONFIG_WLAN=y"
  "CONFIG_CFG80211=m"
  "CONFIG_MAC80211=m"
  "CONFIG_RTW88=m"
  "CONFIG_RTW88_8822ce=m"
  "CONFIG_RTW88_8822cu=m"
  "CONFIG_RTW88_8821cu=m"
  "CONFIG_RTL8192CU=m"
  "CONFIG_RTL8XXXU=m"
  "CONFIG_MT7601U=m"
  "CONFIG_MT76_CORE=m"
  "CONFIG_MT76_USB=m"
  "CONFIG_MT76x0U=m"
  "CONFIG_MT76x2U=m"
  "CONFIG_MT7921E=m"
  "CONFIG_MT7921U=m"
  "CONFIG_ATH9K=m"
  "CONFIG_ATH10K=m"

  # --- 6. 全量磁盘文件系统 ---
  "CONFIG_FAT_FS=m"
  "CONFIG_VFAT_FS=m"
  "CONFIG_EXFAT_FS=m"
  "CONFIG_NTFS_FS=m"
  "CONFIG_NTFS3_FS=m"
  "CONFIG_BTRFS_FS=m"
  "CONFIG_XFS_FS=m"
  "CONFIG_F2FS_FS=m"

  # --- 7. USB 串口芯片 ---
  "CONFIG_USB_SERIAL=m"
  "CONFIG_USB_SERIAL_GENERIC=m"
  "CONFIG_USB_SERIAL_CH341=m"
  "CONFIG_USB_SERIAL_CP210X=m"
  "CONFIG_USB_SERIAL_FTDI_SIO=m"
  "CONFIG_USB_SERIAL_PL2303=m"

  # --- 8. 虚拟网卡与高级网络协议 ---
  "CONFIG_TUN=m"
  "CONFIG_VETH=m"
  "CONFIG_WIREGUARD=m"
)

source .current_config.mk
KCFG=kernel/arch/arm64/configs/$(awk '{print $1}' <<< "$TARGET_KERNEL_CONFIG")

echo "===> 开始智能分析并注入内核配置至 ${KCFG} ..."

for CFG in "${CONFIGS[@]}"; do
  KEY=${CFG%%=*}
  VAL=${CFG#*=}

  # 检查原厂配置文件中的当前状态
  EXISTING_LINE=$(grep -E "^#? ?${KEY}[= ]" "${KCFG}" || true)

  if [ "$VAL" = "n" ]; then
    # 规则 1: 冲突驱动强行禁用 (=n)
    if [ -n "$EXISTING_LINE" ]; then
      sed -i "s@^#\?${KEY}=.*@${KEY}=n@g" "${KCFG}"
    else
      echo "${KEY}=n" >> "${KCFG}"
    fi

  elif [ "$VAL" = "y" ]; then
    # 规则 2: 核心功能强行内置 (=y)
    if [ -n "$EXISTING_LINE" ]; then
      sed -i "s@^#\?${KEY}=.*@${KEY}=y@g" "${KCFG}"
    else
      echo "${KEY}=y" >> "${KCFG}"
    fi

  elif [ "$VAL" = "m" ]; then
    # 规则 3: 针对模块 (=m)，如果原厂已经是 =y (内置)，千万不降级！保持原厂 =y！
    if echo "$EXISTING_LINE" | grep -q "=y"; then
      echo "[保留原厂内置] ${KEY}=y (不降级为模块)"
    elif [ -n "$EXISTING_LINE" ]; then
      sed -i "s@^#\?${KEY}=.*@${KEY}=m@g" "${KCFG}"
    else
      echo "${KEY}=m" >> "${KCFG}"
    fi
  fi
done

echo "===> 智能驱动配置注入完成！"
