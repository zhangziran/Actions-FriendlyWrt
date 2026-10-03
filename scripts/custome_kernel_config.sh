#!/bin/bash

# =========================================================
# NanoPi M5 (RK3576) 6.1 厂商内核全量驱动智能注入脚本
# 1. 完美保留 Panfrost 开源显卡配置 (禁用闭源 Mali KBase)
# 2. 智能防降级：原厂已是 =y 内置的功能，绝不降级为 =m
# 3. 补全 ALSA 声卡核心、蓝牙驱动、全量 USB 网卡、Wi-Fi、文件系统
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

  # --- 2. 声卡底层 ALSA 核心 (对应 kmod-sound-core 的原生实现) ---
  "CONFIG_SOUND=y"
  "CONFIG_SND=y"
  "CONFIG_SND_TIMER=y"
  "CONFIG_SND_PCM=y"
  "CONFIG_SND_DMAENGINE_PCM=y"
  "CONFIG_SND_SOC=y"
  "CONFIG_SND_SOC_ROCKCHIP=y"

  # --- 3. 蓝牙协议栈与驱动 ---
  "CONFIG_BT=m"
  "CONFIG_BT_RFCOMM=m"
  "CONFIG_BT_RFCOMM_TTY=y"
  "CONFIG_BT_BNEP=m"
  "CONFIG_BT_HIDP=m"
  "CONFIG_BT_HS=y"
  "CONFIG_BT_LE=y"
  "CONFIG_BT_HCIBTUSB=m"
  "CONFIG_BT_HCIUART=m"
  "CONFIG_BT_HCIUART_H4=y"
  "CONFIG_BT_HCIUART_BCSP=y"
  "CONFIG_BT_HCIUART_RTL=y"
  "CONFIG_BT_HCIVHCI=m"
  "CONFIG_GPIOLIB=y"
  "CONFIG_GPIO_SYSFS=y"

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

# 1. 提取内核配置文件路径
source .current_config.mk 2>/dev/null || true
DEFCONFIG_NAME=$(awk '{print $1}' <<< "$TARGET_KERNEL_CONFIG")
KCFG="kernel/arch/arm64/configs/${DEFCONFIG_NAME}"

# 2. 增加路径防错容灾校验（防 5 小时构建跑空）
if [ -z "$DEFCONFIG_NAME" ] || [ ! -f "$KCFG" ]; then
    echo "::error::未找到内核配置文件: ${KCFG}"
    echo "当前 TARGET_KERNEL_CONFIG 变量为: ${TARGET_KERNEL_CONFIG}"
    echo "正在搜寻 kernel/arch/arm64/configs/ 路径下的所有配置文件："
    ls -la kernel/arch/arm64/configs/ || true
    exit 1
fi

echo "===> 开始向内核配置文件 [ ${KCFG} ] 智能注入配置..."

# 3. 智能替换与追加逻辑
for CFG in "${CONFIGS[@]}"; do
  KEY=${CFG%%=*}
  VAL=${CFG#*=}

  # 精准匹配 existing line (包含 =y, =m 或 # ... is not set)
  EXISTING_LINE=$(grep -E "^(# )?${KEY}([ =].*)?$" "${KCFG}" || true)

  if [ "$VAL" = "n" ]; then
    if [ -n "$EXISTING_LINE" ]; then
      sed -i -E "s@^(# )?${KEY}([ =].*)?\$@${KEY}=n@g" "${KCFG}"
    else
      echo "${KEY}=n" >> "${KCFG}"
    fi

  elif [ "$VAL" = "y" ]; then
    if [ -n "$EXISTING_LINE" ]; then
      sed -i -E "s@^(# )?${KEY}([ =].*)?\$@${KEY}=y@g" "${KCFG}"
    else
      echo "${KEY}=y" >> "${KCFG}"
    fi

  elif [ "$VAL" = "m" ]; then
    if echo "$EXISTING_LINE" | grep -q "=y"; then
      echo "[保留原厂] ${KEY} 已经是内置 (=y)，跳过覆盖。"
    elif [ -n "$EXISTING_LINE" ]; then
      sed -i -E "s@^(# )?${KEY}([ =].*)?\$@${KEY}=m@g" "${KCFG}"
    else
      echo "${KEY}=m" >> "${KCFG}"
    fi
  fi
done

echo "===> 内核驱动智能配置注入完毕！"
