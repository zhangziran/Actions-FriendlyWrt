#!/bin/bash

sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi

# 2. 彻底切断上层 6.12 kmod 垃圾包的生成
# 注入蓝牙音频（BlueALSA、SBC、APTX支持）、BlueZ 工具、ALSA 工具
cat << 'EOF' >> .config

# 蓝牙管理与 ALSA 音频框架用户态组件
CONFIG_PACKAGE_bluez-utils=y
CONFIG_PACKAGE_bluez-daemon=y
CONFIG_PACKAGE_alsa-utils=y
CONFIG_PACKAGE_alsa-plugins=y

# BlueALSA 蓝牙音频及编解码器 (支持 SBC, APTX)
CONFIG_PACKAGE_bluealsa=y
CONFIG_PACKAGE_sbc=y
EOF
