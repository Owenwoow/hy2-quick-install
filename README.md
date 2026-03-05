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

- 操作系统：`Debian 10+` / `Ubuntu 18.04+` (暂不支持 CentOS 等红帽系系统)
- `root` 或 `sudo` 提权用户执行
- 需确保服务商面板（安全组/防火墙）开放了相应的 **UDP** 端口和跳跃区间端口

## 🚀 安装指南

### 方法一：单行命令部署（推荐极简）

只需登录到您的 VPS，通过 `curl` 一键下载并执行脚本：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Owenwoow/hy2-quick-install/main/install.sh)
```

*(如果在极简系统中提示 `curl` 不存在，请先执行 `apt update && apt install curl -y` 进行安装)*

### 方法二：手动克隆仓库

```bash
git clone https://github.com/Owenwoow/hy2-quick-install.git
cd hy2-quick-install
chmod +x install.sh
bash install.sh
```

## 🛠️ 脚本操作菜单

执行安装命令后，您将看到如下可视化的交互菜单：

```text
[INFO] 欢迎使用由 Owen_W 开发的 Hysteria 2 一键部署脚本
[INFO] 项目地址: https://github.com/Owenwoow/hy2-quick-install
[INFO] ================= 请选择操作 =================
1) 安装 Hysteria 2
2) 卸载/环境清理
3) 清理端口跳跃规则 (iptables)
0) 退出脚本
```

根据您的需求，输入对应的数字（如安装按 `1`，随后跟随提示依次操作即可）。

## 🔧 高级：静默/命令行调用

脚本支持基于命令参数的快速调用，适用于需要无需菜单直接控制的情况：

- **快速彻底卸载与清理**：
  ```bash
  bash install.sh --remove
  # 或者输入
  bash install.sh --uninstall
  ```

## ⚠️ 常见问题

1. **部署完成后连不上怎么办？**
   - 检查您安装时填写的监听端口和**端口跳跃区间**，确保在VPS后台云控制面板的安全策略（防火墙）放行了 **UDP** 协议。
   - 绝大多数情况属于防火墙未将 UDP 端口放通所致。

2. **如何更新 Hysteria2 到最新版？**
   - 由于本脚本底层拉取 Hysteria 官方安装源，您可随时在菜单选择 `1) 安装 Hysteria 2`，同意覆盖安装，即可完成服务端组件的更新替换。

3. **能否更换伪装域名？**
   - 脚本安装过程当中支持修改伪装地址。如果随意填写的地址遭到主动阻断，建议填写常见且存在海外节点的网站，如默认内置提供的 `https://www.bing.com`。

## 🙏 鸣谢 (Acknowledgments)

本项目基于并依赖于以下优秀的开源项目，特此致谢：

- **[Hysteria](https://github.com/apernet/hysteria)**：由 Apernet 团队开发的功能强大的网络通信协议及实用工具，它是本部署脚本的运行核心和基础。

## ⚠️ 免责声明 (Disclaimer)

- 本项目脚本及相关说明仅供个人学习、技术研究以及网络环境测试使用。
- 用户在使用本工具前，请务必了解并遵守您所在国家和地区的法律法规以及云服务提供商的相关使用条款。
- 对于使用本脚本而产生的任何直接或间接的风险、损失或不当行为，作者一概不承担任何责任。**一旦您使用本脚本，即表示您已阅读、理解并接受本免责声明。**

## 📄 参与与支持

本项目旨在造福网络交流技术的快速验证环节，如果对您有一丝帮助，请在页面右上方点击一下 **⭐ Star** 支持！您的鼓励是项目维护与打磨下去的动力！

<div align="center">
  <sub>Made with ❤️ by <b>Owen_W</b>. </sub>
</div>
