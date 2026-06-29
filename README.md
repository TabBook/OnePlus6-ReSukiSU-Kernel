# ReSukiSU 内核 · OnePlus 6 enchilada

适用于一加 6 的定制内核,内置 Root。面向 LineageOS 22.2、Android 15、Linux 4.9.337,非 GKI 设备,代号 enchilada,平台 sdm845。

Root 通过 [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) 以手动 hook 方式编译进内核。无需在 App 内安装任何组件,刷入内核后打开管理器即可使用。

由 VoL 构建与维护。

```
内核版本 : 4.9.337-byVoLResukisu
Root     : ReSukiSU v4.1.0 手动 hook
设备     : OnePlus 6 / enchilada / sdm845
ROM      : LineageOS 22.2 / Android 15
```

---

## ✨ 特性

- ReSukiSU Root,手动 hook,内置于内核,仅 ReSukiSU 管理器。
- 仅信任 ReSukiSU 管理器,已关闭多管理器支持。
- 默认启用 TCP BBR 拥塞控制与 fq 队列规则。
- 默认采用 schedutil EAS 调速器,关闭 SCHEDSTATS,保留原版 EAS/WALT 调校。
- -O2 性能构建。
- zram 提供 zstd 与 lz4 后端。
- 内置 ReSukiSU selinux_hide,可在管理器中开启,默认关闭。无 SUSFS 时仅隐藏 SELinux 状态,不隐藏文件与挂载。
- 使用 Neutron Clang 与 GNU binutils 构建。

当前版本 v3,不含 SUSFS 与 KPM。

---

## 📥 刷机安装

刷机前请先备份 boot 分区。一加 6 在 LineageOS 22 上采用 recovery-in-boot,坏内核会同时破坏 recovery。请在电脑上保留可用的 boot.img,以便随时通过 fastboot flash boot 恢复。

```
adb shell su -c "dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot-backup.img"
adb pull /sdcard/boot-backup.img
```

请使用通过 fastboot 临时引导的 TWRP 刷入,这样不会写入 recovery/boot 分区。

1. 从 [Releases](../../releases) 下载最新的 ReSukiSU-OP6-enchilada-*.zip,以及 enchilada 的 TWRP 镜像 twrp-*-enchilada.img。
2. 重启到 bootloader:`adb reboot bootloader`。
3. 临时引导 TWRP,不要刷入:
   ```
   fastboot boot twrp-x.x.x-x-enchilada.img
   ```
4. 在 TWRP 中进入 高级 → ADB Sideload,然后在电脑上执行:
   ```
   adb sideload ReSukiSU-OP6-enchilada-4.9-v3-VoL-YYYYMMDD.zip
   ```
   若 TWRP 能读取存储,也可直接安装该 zip。
5. 重启进入系统。
6. 打开 ReSukiSU 管理器,应显示已安装,内核为 4.9.337-byVoLResukisu。Root 已在内核中,请勿点击 App 内的安装或刷入按钮。

请勿在 TWRP 内点击 安装 TWRP、Flash Current TWRP 或 Install Recovery Ramdisk。在 recovery-in-boot 设备上,这会把 TWRP 写入 boot 并导致循环进入 TWRP。请始终通过 fastboot boot 临时使用 TWRP。

如无法开机,重启到 bootloader 并执行 fastboot flash boot boot-backup.img。

---

## 🔧 从源码构建

本内核基于 LineageOS sdm845 源码树,集成 ReSukiSU 并应用 patches 目录中的补丁。仓库内的 build.sh 可复现完整的 v3 构建。

锁定的源码版本:

- LineageOS android_kernel_oneplus_sdm845,分支 lineage-22.2,commit 2e921a892c03b8a17b4d82e9b24c2b3aa775c870
- ReSukiSU v4.1.0,commit a4f7744c

```bash
# 1. 工具链:Neutron Clang 与 aarch64 GNU binutils,用于 CROSS_COMPILE。
#    这颗 4.9 内核请勿使用 LLVM=1 或集成汇编器。

# 2. 源码
git clone --depth=1 -b lineage-22.2 \
    https://github.com/LineageOS/android_kernel_oneplus_sdm845 kernel
cd kernel

# 3. 集成 ReSukiSU,手动 hook
curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash

# 4. 应用本仓库补丁,手动 su hook 与 defconfig,以及 4.9 的 set_memory.h 兼容头
git apply ../patches/0001-resukisu-manual-hooks.patch
git apply ../patches/0002-enchilada-defconfig.patch
cp ../patches/set_memory.h arch/arm64/include/asm/set_memory.h

# 5. 构建
export ARCH=arm64
export PATH=<neutron-clang>/bin:$PATH
make O=out enchilada_defconfig
make -j$(nproc) O=out CC=clang \
     CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- \
     Image.gz-dtb
```

将 out/arch/arm64/boot/Image.gz-dtb 打包进 [AnyKernel3](https://github.com/osm0sis/AnyKernel3)。

4.9 内核配合新版 Clang 需通过 KCFLAGS 降级若干无害告警,例如 -Wno-error=implicit-enum-enum-cast。详见 Releases 中的构建脚本。

---

## 🙏 致谢

- [LineageOS](https://github.com/LineageOS/android_kernel_oneplus_sdm845) —— 基础内核源码。
- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) —— Root 方案,3.4+ 手动 hook。
- [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) 与 [KernelSU](https://github.com/tiann/KernelSU) —— 上游来源。
- [AnyKernel3](https://github.com/osm0sis/AnyKernel3),作者 osm0sis —— 可刷入打包。
- Neutron Clang —— 工具链。

---

## 📜 许可证

本仓库的修改与 Linux 内核均采用 GPL-2.0 许可证。详见 [LICENSE](LICENSE)。

## ⚠️ 免责声明

刷入定制内核可能导致无法开机,极端情况下可能损坏设备,一切风险由你自行承担。请务必保留 boot.img 备份。作者不对任何损坏或数据丢失负责。
