#!/usr/bin/env bash
# Hysteria 2 一键部署脚本
# 功能：安装或卸载 Hysteria 2 VPN 服务

set -e  # 遇到错误立即退出
set -u  # 使用未定义的变量时报错

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color（重置颜色）

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}


# 检查是否以root身份运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要以root身份运行"
        echo "请使用: sudo bash $0"
        exit 1
    fi
    log_success "Root权限检查通过"
}

# 显示菜单
show_menu() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Hysteria 2 一键部署工具${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo "1) 安装 Hysteria 2"
    echo "2) 卸载 Hysteria 2"
    echo "3) 退出"
    echo -e "${BLUE}======================================${NC}"
    echo -n "请选择 [1-3]: "
}

# 主菜单逻辑
main_menu() {
    while true; do
        show_menu
        read -r choice  # 读取用户输入
        
        case "$choice" in
            1)
                log_info "开始安装..."
                install_hy2
                ;;
            2)
                log_info "开始卸载..."
                uninstall_hy2
                ;;
            3)
                log_info "退出脚本"
                exit 0
                ;;
            *)
                log_error "无效选择，请输入 1-3"
                ;;
        esac
    done
}


# 脚本主入口
main() {
    log_info "Hysteria 2 部署脚本启动"
    check_root
    main_menu
}

# 执行main函数
main "$@"