#!/bin/bash


# ---------- 颜色输出 ----------
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

log() { echo -e "${CYAN}[INFO]${RESET} $*"; }
ok()  { echo -e "${GREEN}[OK]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $*"; }
die() { echo -e "${RED}[ERR]${RESET} $*" >&2; exit 1; }

# ---------- 工具函数 ----------
gen_pass_20() {
  openssl rand -base64 64 | tr -dc 'A-Za-z0-9' | head -c 20
}


# 依赖安装
dep_install() {
    echo -e "${CYAN}正在更新软件源并静默安装依赖，这可能需要一点时间...${RESET}"

    # 更新系统
    apt-get update > /dev/null
    apt-get upgrade -y > /dev/null

    # 安装必要工具
    apt-get install -y curl wget openssl iptables iptables-persistent > /dev/null
}

# 开启端口跳跃
enable_moport() {
    # 技巧：用 tr 把 - 替换成 :
    local iptables_port=$(echo "${mport}" | tr '-' ':')
    
    # 1. 写入 iptables 规则
    # 这里用到了你在前面定义的 hy_port 变量
    iptables -t nat -A PREROUTING -p udp --dport ${iptables_port} -j REDIRECT --to-ports ${hy_port}
    
    # 2. 持久化保存
    if command -v netfilter-persistent > /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    fi
}



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
}

# ============================================================
#  安装主逻辑（把你现有脚本主体封装成函数）
# ============================================================
Install_Hy2() {
    # 检查服务是否存在
    if [[ -f "/etc/systemd/system/hysteria-server.service" ]]; then
        echo -e "${YELLOW}警告：检测到 Hysteria 2 服务已存在！${RESET}"
        read -p "是否覆盖安装？(y/n, 默认n): " CONFIRM
        CONFIRM=${CONFIRM:-n}
        if [[ "${CONFIRM}" != "y" ]]; then
            echo -e "${CYAN}已取消安装。${RESET}"
            return # 跳出函数，回到菜单
        fi
    fi

    # 安装环境和依赖
    dep_install

    # ---------- 交互输入 ----------
    echo -e "${CYAN}========== Hysteria 2 一键部署脚本 ==========${RESET}"

    # 1) 密码：用户自定义 或 自动生成 20 位
    read -p "请输入密码（直接回车=自动生成20位强随机密码）: " user_pass
    if [[ -z "$ user_pass}" ]]; then
    pass="$(gen_pass_20)"
    ok "已生成随机密码：${pass}"
    else
    pass="$ user_pass}"
    ok "使用用户提供的密码"
    fi

    # 2) 端口：选择 hysteria2 的监听端口
    read -p "请输入 Hysteria 2 监听端口 (默认=443): " hy_port
    hy_port=${hy_port:-443} # 默认443

    # 3) IP：自动获取服务的公网IP
    server_ip=$(curl -s https://api.ip.sb/ip)

    # 4) 伪装网站
    read -p "请输入伪装网站 (默认=https://www.bing.com): " fake_url
    fake_url=${fake_url:-https://www.bing.com} # 默认https://www.bing.com

    # 5) 节点名称：用户输入 或 随机系统命名
    read -p "请输入节点名称（直接回车=自动生成系统命名）: " node_name
    if [[ -z "${node_name}" ]]; then
        # 随机生成：取前 8 位 IP + 4 位随机数字
        node_name="hy2-$(printf "%04d" $((RANDOM % 10000)))"
        ok "已生成随机节点名：${node_name}"
    else
        ok "使用用户提供的节点名"
    fi

    # 6) 端口跳跃：自动生成 20000-30000 范围内的随机端口
    read -p "是否启用 UDP 端口跳跃 20000-20100 -> 443？（回车=启用 / 输入 n=不需要）: " port_jump_change
    # 如果用户直接按回车，我们将变量设为 y
    port_jump_change=${port_jump_change:-y}
    if [[ "${port_jump_change}" == "y" ]]; then
        read -p "请输入 UDP 端口跳跃范围（默认=20000-20100）: " mport
        mport=${mport:-20000-20100}
        # 执行端口跳跃
        enable_moport
        echo -e "${GREEN}-> 已启用端口跳跃${RESET}"
    else
        # 处理用户输入了 y/n 之外的其他字符（容错处理）
        echo -e "${RED}-> 输入无效，默认不启用端口跳跃${RESET}"
    fi




# ============================================================
#  入口：参数触发 或 菜单触发
# ============================================================
menu() {
    # 参数触发（适合自动化）：./install.sh --remove
    case "${1:-}" in
    --remove|--uninstall)
        Uninstall_Hy2
        ;;
    esac

    # 菜单触发（交互使用）
    echo -e "${CYAN}欢迎使用由 Owen_W 开发的 Hysteria 2 一键部署脚本${RESET}"
    echo -e "${CYAN}================= 请选择操作 =================${RESET}"
    echo "1) 安装 Hysteria 2"
    echo "2) 卸载/环境清理"
    read -p "请输入选项 [1-2]（默认1）：" CHOICE
    CHOICE="${CHOICE:-1}"

    case "${CHOICE}" in
    1) Install_Hy2 ;;
    2) Uninstall_Hy2 ;;
    *) warn "无效选项：${CHOICE}，默认执行安装"; Install_Hy2 ;;
    esac
}


# ============================================================
#  主函数（入口）
# ============================================================
main() {
    check_root
    menu
}


# 执行主函数
main "$@"

