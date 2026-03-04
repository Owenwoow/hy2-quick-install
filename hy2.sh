#!/bin/bash

# 交互式输入，确认变量
## Hysteria 2 监听端口
# read -p "请输入 Hysteria 2 监听端口 [默认 443]: " hy_port
# hy_port=${hy_port:-443} # 默认443

# ## Hysteria 2 密码
# read -p "请输入密码（直接回车=自动生成20位强随机密码）: " hy_password
# def_password="$(openssl rand -base64 64 | tr -dc 'A-Za-z0-9' | head -c 20)"
# hy_password=${hy_password:-$def_password} # 默认password

# # 获取服务器公网IP
# server_ip=$(curl -s https://api.ip.sb/ip)


# ---------- 颜色输出 ----------
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"


# ============================================================
#  检查 root 权限的函数
# ============================================================
check_root() {
    # 检查是否为root用户执行
    if [ $(id -u) != "0" ]; then
        echo -e "${RED}错误：${RESET} 请以 root 用户执行脚本！${RESET}"
        exit 1
    fi

    # 检查操作系统是否为Debian/Ubuntu
    if ! grep -qiE "debian|ubuntu" /etc/os-release; then
        echo -e "${RED}错误：${RESET} 本脚本仅支持 Debian/Ubuntu 系统！${RESET}"
        exit 1
    fi    

    # 更新系统并安装必要工具
    echo -e "${CYAN}正在初始化环境，这可能需要一点时间...${RESET}"
    
        # 更新系统
        apt-get update > /dev/null
        apt-get upgrade -y > /dev/null

        # 安装必要工具
        apt-get install -y curl wget > /dev/null
    }

# ============================================================
#  安装主逻辑（把你现有脚本主体封装成函数）
# ============================================================
Install_Hy2() {
    echo "这里负责具体的安装逻辑..."
}


# ============================================================
#  主函数（入口）
# ============================================================
main() {
    # 逻辑：先检查权限，再显示菜单
    check_root
    echo "欢迎使用 Hysteria 2 安装脚本"
    # 我们之后在这里写逻辑让用户选 [1] 安装 或 [2] 卸载
}


# 执行主函数
main "$@"

