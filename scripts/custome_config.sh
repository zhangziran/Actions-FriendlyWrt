#!/bin/bash
set -e

# =========================================================
# 最终修正版: FriendlyWrt 上层 OpenWrt 配置注入脚本
# 1. 先全量更新/安装 feeds，确保 OpenWrt 能够识别 BlueALSA 软件包
# 2. 将配置同时注入 configs/ 种子文件，防止后续 ./build.sh 覆盖重写 .config
# =========================================================

# --- 第一步：进入 friendlywrt 提前更新并安装 feeds ---
if [ -d "friendlywrt" ]; then
    echo "===> 正在提前更新并安装 friendlywrt feeds 包索引..."
    cd friendlywrt
    ./scripts/feeds update -a 2>/dev/null || true
    ./scripts/feeds install -a 2>/dev/null || true
    cd ..
fi

# --- 第二步：寻找 configs/ 下所有的目标种子配置文件 ---
CONFIG_FILES=$(find configs/ -type f \( -name "01-nanopi*" -o -name "rockchip*" \) 2>/dev/null || true)

if [ -z "$CONFIG_FILES" ]; then
    echo "::warning:: 未找到指定配置文件，尝试匹配 configs/ 下所有文件..."
    CONFIG_FILES=$(find configs/ -type f 2>/dev/null || true)
fi

echo "===> 找到以下目标种子配置文件，准备注入："
echo "$CONFIG_FILES"

# 定义要注入的音频与蓝牙配置块
AUDIO_CONFIGS=$(cat << 'EOF'

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
)

# 循环修改每个种子文件
for CFG in $CONFIG_FILES; do
    echo "===> 正在注入配置到种子文件: $CFG"

    # 精简开发包体积
    sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' "$CFG"
    sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' "$CFG"
    sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' "$CFG"

    # 清理旧配置防止重复追加
    sed -i -e '/CONFIG_PACKAGE_bluez-alsa/d' "$CFG"
    sed -i -e '/CONFIG_PACKAGE_sbc/d' "$CFG"
    sed -i -e '/CONFIG_PACKAGE_bluez-daemon/d' "$CFG"

    # 追加 BlueALSA 全家桶配置
    echo "$AUDIO_CONFIGS" >> "$CFG"
done

# --- 第三步：如果当前目录下已有 .config，同步追加一份作为双保险 ---
if [ -f "friendlywrt/.config" ]; then
    echo "===> 同步注入到 friendlywrt/.config ..."
    sed -i -e '/CONFIG_PACKAGE_bluez-alsa/d' friendlywrt/.config
    echo "$AUDIO_CONFIGS" >> friendlywrt/.config
fi

echo "===> OpenWrt 用户态包配置注入完成！"
