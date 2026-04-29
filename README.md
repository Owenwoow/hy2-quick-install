# Hysteria 2 一键部署脚本

<div align="center">
  <img src="https://img.shields.io/badge/OS-Debian%20%7C%20Ubuntu-blue" alt="OS Support">
  <img src="https://img.shields.io/badge/Hysteria-2.x-green" alt="Hysteria Version">
  <img src="https://img.shields.io/badge/Author-Owen__W-orange" alt="Author">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
</div>

> **项目地址**: [https://github.com/Owenwoow/hy2-quick-install](https://github.com/Owenwoow/hy2-quick-install)

为您带来极为简洁、稳定且功能完善的 **Hysteria 2** 服务端一键自动化部署工具。


## ⚙️ 系统要求

- 操作系统：`Debian 10+` / `Ubuntu 18.04+`（暂不支持 CentOS 等红帽系系统）
- `root` 用户执行
- 确保服务商面板（安全组 / 防火墙）已放行对应的 **UDP** 端口及跳跃区间端口


## 🚀 安装指南

### 方法一：单行命令部署（推荐）

登录 VPS 后直接执行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Owenwoow/hy2-quick-install/main/install.sh)
```

> 若提示 `curl` 不存在，请先执行 `apt update && apt install curl -y`

### 方法二：手动克隆仓库

```bash
git clone https://github.com/Owenwoow/hy2-quick-install.git
cd hy2-quick-install
chmod +x install.sh
bash install.sh
```


## 🛠️ 脚本操作菜单

执行脚本后将看到如下交互菜单：

```text
[INFO] 欢迎使用由 Owen_W 开发的 Hysteria 2 一键部署脚本
[INFO] 项目地址: https://github.com/Owenwoow/hy2-quick-install
[INFO] ================= 请选择操作 =================
1) 安装 Hysteria 2
2) 卸载/环境清理
3) 清理端口跳跃规则 (iptables)
4) 读取订阅连接
5) 快速安装（请手动完成依赖部分的安装）
0) 退出脚本
```

| 选项 | 功能说明 |
|------|---------|
| `1` | 标准安装：自动完成依赖安装 → 交互配置 → 启动服务 → 输出客户端 URI |
| `2` | 卸载并清理所有配置、证书、服务文件及 sysctl 优化 |
| `3` | 单独管理 iptables 端口跳跃规则（查看 / 按行号删除） |
| `4` | **读取订阅连接**：直接输出已保存的客户端 URI；若缓存不存在则自动从配置重新生成 |
| `5` | **快速安装**：跳过依赖安装步骤，适合已手动安装依赖的环境 |
| `0` | 退出脚本 |


## 📋 选项 4 — 读取订阅连接

安装完成后，客户端 URI 会自动保存到 `/etc/hysteria/link.bak`。

选择 `4) 读取订阅连接` 时脚本执行逻辑：

1. 检测 Hysteria 2 是否已安装（同时检测 `hysteria` 命令和 systemd 服务，任意一项存在即视为已安装）
2. 若 `/etc/hysteria/link.bak` 存在且非空 → 直接输出
3. 若缓存文件不存在 → 从 `config.yaml` 读取端口 / 密码，自动获取公网 IP，检测 iptables 端口跳跃规则，重新生成 URI 并保存到 `link.bak`


## ⚡ 选项 5 — 快速安装

适用于已通过其他方式完成依赖安装的场景（如在容器内或自定义镜像中）。

执行前请确保以下依赖已就绪：

```bash
apt-get install -y curl wget openssl iptables iptables-persistent
```

选择 `5` 后脚本将直接进入配置交互，**跳过** `apt-get update / upgrade` 及依赖安装步骤。


## 🔧 高级：命令行参数

脚本支持非交互式直接调用：

```bash
# 快速卸载并清理
bash install.sh --remove
# 或
bash install.sh --uninstall
```


## ⚠️ 常见问题

**1. 部署完成后连不上？**
- 检查监听端口和端口跳跃区间，确保 VPS 安全组已放行 **UDP** 协议。
- 绝大多数情况属于防火墙未放通 UDP 端口所致。

**2. 如何更新 Hysteria 2？**
- 菜单选择 `1) 安装 Hysteria 2`，同意覆盖安装即可完成更新。

**3. 能否更换伪装域名？**
- 安装过程中可自定义伪装网站 URL；若遭到阻断，建议填写具有海外节点的常见网站（默认为 `https://www.bing.com`）。

**4. 安装完成后如何再次查看客户端 URI？**
- 菜单选择 `4) 读取订阅连接` 即可直接输出，无需重新安装。


## 🙏 鸣谢

- **[Hysteria](https://github.com/apernet/hysteria)**：由 Apernet 团队开发的高性能网络协议，是本脚本的运行核心。


## ⚠️ 免责声明

- 本项目仅供个人学习、技术研究及网络环境测试使用。
- 使用前请了解并遵守所在国家和地区的法律法规及云服务商的使用条款。
- 对于使用本脚本产生的任何风险、损失或不当行为，作者概不负责。**使用即表示您已阅读、理解并接受本声明。**


## 📄 参与与支持

如果本项目对您有帮助，请点击右上角 **⭐ Star** 支持！您的鼓励是持续维护的动力！

<div align="center">
  <sub>Made with ❤️ by <b>Owen_W</b>. </sub>
</div>
