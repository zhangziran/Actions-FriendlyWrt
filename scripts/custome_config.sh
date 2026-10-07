#!/bin/bash

# =========================================================
# FriendlyWrt 上层 OpenWrt 配置注入脚本
# 1. 精简 SDK/Toolchain/IB 以节省 CI 磁盘空间并加速编译
# 2. 精确注入蓝牙、ALSA 音频及 BlueALSA 软件包全家桶
# =========================================================

# 兼容 01-nanopi 与 01-nanopi-docker 配置文件
for CFG in configs/rockchip/01-nanopi configs/rockchip/01-nanopi-docker; do
    [ -f "$CFG" ] || continue

    # 1. 裁掉不必要的开发包打包（节省 Actions 磁盘空间，防止编译超时或爆磁盘）
    sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' "$CFG"
    sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' "$CFG"
    sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' "$CFG"

    # 2. 清理旧配置，防止重复追加
    sed -i -e '/CONFIG_ALL_KMODS/d' "$CFG"
    sed -i -e '/CONFIG_ALL_NONSELECT/d' "$CFG"
    sed -i -e '/CONFIG_PACKAGE_bluez-alsa/d' "$CFG"
    sed -i -e '/CONFIG_PACKAGE_bluealsa/d' "$CFG"

    # 3. 追加蓝牙与 BlueALSA 完整依赖链至种子配置文件
    cat << 'EOF' >> "$CFG"
# 显式声明 C 库与系统总线依赖，防止 make defconfig 静默剔除 bluealsa
CONFIG_PACKAGE_dbus=y
CONFIG_PACKAGE_glib2=y

# 蓝牙与音频内核驱动模块
CONFIG_PACKAGE_kmod-sound-core=y
CONFIG_PACKAGE_kmod-bluetooth=y

# 蓝牙管理工具与守护进程
CONFIG_PACKAGE_bluez-daemon=y
CONFIG_PACKAGE_bluez-utils=y

# ALSA 声卡框架及插件
CONFIG_PACKAGE_alsa-lib=y
CONFIG_PACKAGE_alsa-utils=y
CONFIG_PACKAGE_alsa-plugins=y

# SBC 编解码器与 BlueALSA 核心服务
CONFIG_PACKAGE_sbc=y
CONFIG_PACKAGE_bluez-alsa=y
EOF
done
