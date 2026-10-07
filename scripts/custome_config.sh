#!/bin/bash

# =========================================================
# FriendlyWrt 上层 OpenWrt 配置注入脚本
# 1. 强制补全缺失的多媒体音频包 (bluez-alsa, sbc)
# 2. 精简 SDK/Toolchain/IB 以节省 CI 磁盘空间
# 3. 精确注入蓝牙、ALSA 音频及 BlueALSA 软件包全家桶
# =========================================================

# --- 新增：强制拉取 OpenWrt 官方库的 bluez-alsa 和 sbc ---
echo "===> 正在从 OpenWrt 官方库强制补全缺失的多媒体包..."
mkdir -p friendlywrt/package/custom_packages
cd friendlywrt/package/custom_packages
# 浅克隆官方 packages 仓库（耗时仅需几秒）
git clone --depth 1 https://github.com/openwrt/packages.git openwrt_pkgs
# 提取所需的音频包到上层 package 目录
cp -r openwrt_pkgs/sound/bluez-alsa ../
cp -r openwrt_pkgs/sound/sbc ../
# 清理无用文件并返回项目根目录
cd ..
rm -rf custom_packages
cd ../..
echo "===> 源码补全完毕！"

# 1. 裁掉不必要的开发包打包
sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi

# 2. 清理旧配置，防止重复追加
sed -i -e '/CONFIG_ALL_KMODS/d' configs/rockchip/01-nanopi
sed -i -e '/CONFIG_ALL_NONSELECT/d' configs/rockchip/01-nanopi

# 2. 追加全量配置 (严格使用官方标准包名 bluez-alsa)
cat << 'EOF' >> configs/rockchip/01-nanopi
CONFIG_PACKAGE_dbus=y
CONFIG_PACKAGE_glib2=y
CONFIG_PACKAGE_kmod-sound-core=y
CONFIG_PACKAGE_kmod-bluetooth=y
CONFIG_PACKAGE_bluez-daemon=y
CONFIG_PACKAGE_bluez-utils=y
CONFIG_PACKAGE_alsa-lib=y
CONFIG_PACKAGE_alsa-utils=y
CONFIG_PACKAGE_alsa-plugins=y
CONFIG_PACKAGE_sbc=y
CONFIG_PACKAGE_bluez-alsa=y
EOF
