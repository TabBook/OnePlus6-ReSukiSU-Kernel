# ReSukiSU 内核 · OnePlus 6（enchilada）

为运行 **LineageOS 22.2**（Android 15，Linux **4.9.337**，非 GKI）的
**一加 6（OnePlus 6 / enchilada / sdm845）** 打造的 **自带 Root** 定制内核。

Root 通过 [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) 以 **手动 hook**
方式直接 **编译进内核**（这是老的非 GKI 内核最稳妥的方案）——无需在 App 里
“安装”任何东西：刷入内核、打开管理器即可。

由 **VoL** 构建与维护。

```
内核版本 : 4.9.337-byVoLResukisu
Root     : ReSukiSU v4.1.0（手动 hook）
设备     : OnePlus 6 / enchilada / sdm845
ROM      : LineageOS 22.2（Android 15）
```

---

## ✨ 特性

- **ReSukiSU Root**（手动 hook，内置）—— 内核级 Root，仅 ReSukiSU 管理器。
- **仅信任 ReSukiSU 管理器** —— 已关闭多管理器支持，只信任 ReSukiSU App
  （MKSU / RKSU / KOWSU / SukiSU-Ultra 均不被接受）。
- **TCP BBR** 拥塞控制 + `fq` 队列规则，并设为默认 —— Wi-Fi 与移动数据下
  吞吐与延迟更好。
- **均衡的调度 / 功耗** —— 默认以 `schedutil`（EAS）调速器启动，而非
  `performance`；关闭 `SCHEDSTATS` 以减少调度器开销。其余原版 EAS/WALT
  调校保持不变。
- **`-O2` 构建** —— 以性能而非体积为目标编译。
- **额外 zram 后端** —— 提供 `zstd`（压缩比更高）与 `lz4`（更快）。
- **隐藏 SELinux 状态** —— 内置 ReSukiSU `selinux_hide`；在 ReSukiSU 管理器中
  开启后，可让 App 读到 SELinux 为 *Enforcing*（默认关闭）。无 SUSFS 时
  仅隐藏 SELinux 状态，不隐藏文件 / 挂载。
- 使用 **Neutron Clang** + GNU binutils 构建。

> 当前为 **v3**。本版本 **不含 SUSFS、不含 KPM**（保持简洁与稳定）。

---

## 📥 刷机安装

> ⚠️ **请先备份当前的 `boot` 分区。** 一加 6 在 LineageOS 22 上采用
> **recovery-in-boot**（recovery 集成在 boot 里），坏内核同样会破坏 recovery。
> 务必在电脑上保留一份可用的 `boot.img`，以便随时用 `fastboot flash boot` 恢复。
>
> ```
> adb shell su -c "dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot-backup.img"
> adb pull /sdcard/boot-backup.img
> ```

请使用通过 fastboot **临时引导（boot）的 TWRP** 刷入 —— 这样不会写入
recovery/boot 分区，因此不会损坏设备。

1. 从 [**Releases**](../../releases) 下载最新的
   `ReSukiSU-OP6-enchilada-*.zip`，以及一份 **enchilada** 的 TWRP 镜像
   （`twrp-*-enchilada.img`）。
2. 重启到 bootloader：`adb reboot bootloader`。
3. **临时引导**（不要刷入）TWRP：
   ```
   fastboot boot twrp-x.x.x-x-enchilada.img
   ```
4. 在 TWRP 中进入 `高级 (Advanced)` → `ADB Sideload`，然后在电脑上执行：
   ```
   adb sideload ReSukiSU-OP6-enchilada-4.9-v3-VoL-YYYYMMDD.zip
   ```
   （若 TWRP 能读取存储，也可直接 `安装 (Install)` 该 zip。）
5. 重启进入系统。
6. 打开 **ReSukiSU 管理器** —— 应已显示 *已安装*，内核为
   `4.9.337-byVoLResukisu`。（**不要**点击 App 里的任何“安装/刷入”按钮，
   Root 已经在内核里了。）

> 🚫 **切勿** 在 TWRP 内点击 *“安装 TWRP / Flash Current TWRP /
> Install Recovery Ramdisk”*。在这种 recovery-in-boot 设备上，这会把 TWRP
> 写进 `boot`，导致循环进入 TWRP。请始终用 `fastboot boot` **临时**使用 TWRP。

**万一无法开机：** 重启到 bootloader 并执行
`fastboot flash boot boot-backup.img`。

---

## 🔧 从源码构建

本内核基于 LineageOS sdm845 源码树，集成 ReSukiSU 并应用
[`patches/`](patches/) 中的补丁。仓库内的 [`build.sh`](build.sh) 可一键复现
完整的 v3 构建。

**锁定的源码版本（v3）：**
- LineageOS `android_kernel_oneplus_sdm845` @ `lineage-22.2`，commit
  `2e921a892c03b8a17b4d82e9b24c2b3aa775c870`
- ReSukiSU `v4.1.0`（`a4f7744c`）

```bash
# 1. 工具链：Neutron Clang（clang）+ aarch64 GNU binutils（用于 CROSS_COMPILE）。
#    （这颗 4.9 内核请勿使用 LLVM=1 / 集成汇编器。）

# 2. 源码
git clone --depth=1 -b lineage-22.2 \
    https://github.com/LineageOS/android_kernel_oneplus_sdm845 kernel
cd kernel

# 3. 集成 ReSukiSU（手动 hook）
curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash

# 4. 应用本仓库的补丁（手动 su hook + defconfig）
#    以及 4.9 的 set_memory.h 兼容头
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

将 `out/arch/arm64/boot/Image.gz-dtb` 打包进
[AnyKernel3](https://github.com/osm0sis/AnyKernel3)。

> 4.9 内核 + 新版 Clang 需要通过 `KCFLAGS` 降级几个无害告警
> （如 `-Wno-error=implicit-enum-enum-cast`）。详见 Releases 中的构建脚本。

---

## 🙏 致谢

- [**LineageOS**](https://github.com/LineageOS/android_kernel_oneplus_sdm845) —— 基础内核源码。
- [**ReSukiSU**](https://github.com/ReSukiSU/ReSukiSU) —— Root 方案（3.4+ 手动 hook）。
- [**SukiSU-Ultra**](https://github.com/SukiSU-Ultra/SukiSU-Ultra) / [**KernelSU**](https://github.com/tiann/KernelSU) —— 上游来源。
- [**AnyKernel3**](https://github.com/osm0sis/AnyKernel3)（作者 osm0sis）—— 可刷入打包。
- **Neutron Clang** —— 工具链。

---

## 📜 许可证

Linux 内核及本仓库的修改均以
**GNU 通用公共许可证 v2.0（GPL-2.0）** 授权。详见 [`LICENSE`](LICENSE)。

## ⚠️ 免责声明

刷入定制内核可能导致无法开机，极端情况下甚至可能损坏设备。一切风险
**由你自行承担**。请务必保留 `boot.img` 备份。作者不对任何损坏或数据丢失负责。
