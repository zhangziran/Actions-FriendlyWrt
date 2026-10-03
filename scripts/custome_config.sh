#!/bin/bash

# =========================================================
# FriendlyWrt 上层 OpenWrt 配置注入脚本
# 1. 禁用无用 6.12 kmod 及全量软件包离线打包
# 2. 精确注入蓝牙、ALSA 音频及 BlueALSA 软件全家桶
# =========================================================

# 1. 清理基础构建选项
sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi

# 2. 先清理可能存在的旧配置，防止重复追加
sed -i -e '/CONFIG_ALL_KMODS/d' configs/rockchip/01-nanopi
sed -i -e '/CONFIG_ALL_NONSELECT/d' configs/rockchip/01-nanopi

# 3. 将目标配置精确追加写入种子配置文件 01-nanopi 中
cat << 'EOF' >> configs/rockchip/01-nanopi
# 彻底切断无用 6.12 .apk 离线驱动包的生成
# CONFIG_ALL_KMODS is not set
# CONFIG_ALL_NONSELECT is not set

# 勾选内核模块标志（仅用于通过 bluealsa 的编译期依赖检查）
CONFIG_PACKAGE_kmod-sound-core=y
CONFIG_PACKAGE_kmod-bluetooth=y

# 蓝牙管理工具与 ALSA 音频框架用户态组件
CONFIG_PACKAGE_bluez-utils=y
CONFIG_PACKAGE_bluez-daemon=y
CONFIG_PACKAGE_alsa-utils=y
CONFIG_PACKAGE_alsa-plugins=y

# BlueALSA 蓝牙音频服务及 SBC/APTX 编解码器
CONFIG_PACKAGE_bluealsa=y
CONFIG_PACKAGE_sbc=y
EOF
