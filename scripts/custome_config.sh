#!/bin/bash

sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi
# =========================================================
# 开启 OpenWrt 全局全量编译模式 (=m)
# 自动将 feeds 与内核中的所有软件包和驱动编译为独立的 .apk 离线包
# 固件镜像 (.img.gz) 保持纯净，全量离线包合集放入 packages.tgz 中
# =========================================================
cat << 'EOF' >> .config
CONFIG_ALL=y
CONFIG_ALL_KMODS=y
CONFIG_ALL_NONSELECT=y
EOF
