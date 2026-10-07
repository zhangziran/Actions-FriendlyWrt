#!/bin/bash
set -e

# =========================================================
# FriendlyWrt 上层 OpenWrt 配置注入脚本
# 1. 精简 SDK/Toolchain/IB 以节省 CI 磁盘空间
# 2. 精确注入蓝牙、ALSA 音频及 BlueALSA 软件包全家桶
# =========================================================

TARGET_CONFIG="configs/rockchip/01-nanopi"

# 防错校验：检查目标配置文件是否存在
if [ ! -f "$TARGET_CONFIG" ]; then
    echo "::error::未找到目标配置文件: ${TARGET_CONFIG}"
    exit 1
fi

echo "===> 开始向 OpenWrt 配置文件 [ ${TARGET_CONFIG} ] 注入用户态包..."

# 1. 裁掉不必要的开发包打包（精简体积）
sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' "$TARGET_CONFIG"
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' "$TARGET_CONFIG"
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' "$TARGET_CONFIG"

# 2. 清理旧配置，防止重复追加
sed -i -e '/CONFIG_ALL_KMODS/d' "$TARGET_CONFIG"
sed -i -e '/CONFIG_ALL_NONSELECT/d' "$TARGET_CONFIG"

# 3. 追加全量用户态音频与蓝牙配置 (严格使用官方标准包名 bluez-alsa)
cat << 'EOF' >> "$TARGET_CONFIG"

# --- BlueALSA Core & Mandatory Dependencies ---
CONFIG_PACKAGE_dbus=y
CONFIG_PACKAGE_glib2=y
CONFIG_PACKAGE_sbc=y
CONFIG_PACKAGE_bluez-alsa=y

# --- Linux Kernel Audio & Bluetooth Drivers ---
CONFIG_PACKAGE_kmod-sound-core=y
CONFIG_PACKAGE_kmod-bluetooth=y

# --- BlueZ Subsystem & Tools ---
CONFIG_PACKAGE_bluez-daemon=y
CONFIG_PACKAGE_bluez-utils=y

# --- ALSA Framework & Utilities ---
CONFIG_PACKAGE_alsa-lib=y
CONFIG_PACKAGE_alsa-utils=y
CONFIG_PACKAGE_alsa-plugins=y
EOF

echo "===> OpenWrt 用户态包配置注入完成！"
