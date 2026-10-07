#!/bin/bash
set -e

# =========================================================
# 修正版: FriendlyWrt 上层 OpenWrt 配置注入脚本
# 1. 匹配并精简 SDK/Toolchain/IB 以节省 CI 磁盘空间
# 2. 先全量更新 feeds，确保软件包在本地就绪
# 3. 将 BlueALSA 全家桶直接注入最终的 .config 并用 defconfig 修复依赖树
# =========================================================

# --- 第一步：裁剪种子配置文件的臃肿选项 ---
CONFIG_FILES=$(find configs/rockchip/ -type f -name "01-nanopi*" 2>/dev/null || true)

if [ -z "$CONFIG_FILES" ]; then
    echo "::warning:: 未找到 01-nanopi* 配置文件，尝试匹配 configs/rockchip/ 下所有配置文件..."
    CONFIG_FILES=$(find configs/rockchip/ -type f 2>/dev/null || true)
fi

echo "===> 正在精简目标种子配置文件（剥离 SDK/IB）..."
for CFG in $CONFIG_FILES; do
    sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' "$CFG"
    sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' "$CFG"
    sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' "$CFG"
    
    # 清理种子文件中可能残留的错误追加，防止干扰
    sed -i -e '/CONFIG_PACKAGE_bluez-alsa/d' "$CFG"
    sed -i -e '/CONFIG_PACKAGE_sbc/d' "$CFG"
done

# --- 第二步：进入源码目录，更新 Feeds 并强制注入最终配置 ---
if [ -d "friendlywrt" ]; then
    echo "===> 进入 friendlywrt 目录处理软件包和依赖..."
    cd friendlywrt

    # [关键修改1] 必须先完整更新并安装 feeds，确保基础环境识别到这些包
    echo "===> 1. 正在更新并安装 feeds..."
    ./scripts/feeds update -a 2>/dev/null || true
    ./scripts/feeds install -a 2>/dev/null || true

    # [关键修改2] 直接向最终生效的 .config 追加，而不是写进种子文件
    echo "===> 2. 正在向 .config 注入音频与蓝牙包..."
    cat << 'EOF' >> .config

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

    # [关键修改3] 注入完毕后，运行 defconfig 让 OpenWrt 自动计算并开启关联的隐藏依赖项
    echo "===> 3. 运行 make defconfig 自动修复和对齐依赖树..."
    make defconfig

    cd ..
else
    echo "::error:: 未找到 friendlywrt 目录，请检查执行路径是否正确！"
    exit 1
fi

echo "===> OpenWrt 用户态包配置注入与依赖修复完成！"
