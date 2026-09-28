#!/bin/bash

sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi

# =========================================================
# 仅全量编译所有内核驱动模块 (kmod-*)
# 1. 覆盖 100% 的 USB 网卡、无线网卡、USB 设备、文件系统驱动
# 2. 生成离线 .apk 包存入 Releases 的 packages-*.tgz 中
# 3. 避免编译无用大型 C++ 应用，确保 GitHub Actions 绝不爆盘
# =========================================================
cat << 'EOF' >> .config
CONFIG_ALL_KMODS=y
CONFIG_ALL_NONSELECT=y
EOF
