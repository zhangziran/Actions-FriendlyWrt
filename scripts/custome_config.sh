#!/bin/bash

# 1. 基础编译参数清理
sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi

# 2. 彻底关闭全量离线包打包，仅精细化编译蓝牙/音频软件及其编译依赖
cat << 'EOF' >> .config
# 禁用无用 6.12 kmod 全量离线包打包
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
