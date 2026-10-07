#!/bin/bash
set -e

# =========================================================
# FriendlyWrt 上层 OpenWrt 配置注入脚本
# 1. 匹配 Rockchip 所有 NanoPi 配置文件 (包含 docker 和 non-docker)
# 2. 精简 SDK/Toolchain/IB 以节省 CI 磁盘空间
# 3. 补全 feeds 符号链接并注入 BlueALSA 全家桶
# =========================================================

# 1. 自动查找 configs/rockchip/ 下所有 01-nanopi 开头的文件 (包含 01-nanopi 和 01-nanopi-docker)
CONFIG_FILES=$(find configs/rockchip/ -type f -name "01-nanopi*" 2>/dev/null || true)

if [ -z "$CONFIG_FILES" ]; then
    echo "::warning:: 未找到 01-nanopi* 配置文件，尝试匹配 configs/rockchip/ 下所有配置文件..."
    CONFIG_FILES=$(find configs/rockchip/ -type f 2>/dev/null || true)
fi

echo "===> 找到以下目标配置文件："
echo "$CONFIG_FILES"

for CFG in $CONFIG_FILES; do
    echo "===> 正在向配置文件 [ $CFG ] 注入用户态音频包配置..."

    # 裁剪不必要的开发包打包（精简体积）
    sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' "$CFG"
    sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' "$CFG"
    sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' "$CFG"

    # 清理旧配置，防止重复追加
    sed -i -e '/CONFIG_ALL_KMODS/d' "$CFG"
    sed -i -e '/CONFIG_ALL_NONSELECT/d' "$CFG"
    sed -i -e '/CONFIG_PACKAGE_bluez-alsa/d' "$CFG"
    sed -i -e '/CONFIG_PACKAGE_sbc/d' "$CFG"

    # 追加全量用户态音频与蓝牙配置
    cat << 'EOF' >> "$CFG"

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
done

# 2. 确保源码树中已将 packages 源的软件节点正确安装至 package/feeds/
if [ -d "friendlywrt" ]; then
    echo "===> 正在更新并安装 friendlywrt feeds 包索引..."
    cd friendlywrt
    ./scripts/feeds update packages 2>/dev/null || true
    ./scripts/feeds install -a -p packages 2>/dev/null || true
    cd ..
fi

echo "===> OpenWrt 用户态包配置注入完成！"
