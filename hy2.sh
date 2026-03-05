#!/bin/bash
set -euo pipefail


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

# 获取默认出口网卡
get_default_iface() {
    ip route show default | awk '/^default/{print $5; exit}'
}

# 获取公网 IPv4
get_public_ipv4() {
    local ip=""
    # 强制通过 IPv4 协议向多个 API 请求
    ip="$(curl -4 -s --max-time 5 https://api.ip.sb/ip 2>/dev/null || true)"
    
    # 正则校验：如果不是标准的 IPv4 格式，则尝试下一个备用源
    if [[ ! "${ip}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        ip="$(curl -4 -s --max-time 5 https://api4.ipify.org 2>/dev/null || true)"
    fi
    
    if [[ ! "${ip}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        ip="$(curl -4 -s --max-time 5 https://ifconfig.me 2>/dev/null || true)"
    fi
    
    echo "${ip}"
}

# URL 片段编码（节点名中的特殊字符）
urlencode_fragment() {
    python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null \
    || printf '%s' "$1"
}

# 更安全的 read：避免无TTY或EOF时触发 set -e 导致脚本直接退出
safe_read() {
    local __var="$1"
    local __prompt="$2"
    local __tmp=""
    # shellcheck disable=SC2162
    if read -r -p "${__prompt}" __tmp; then
        :
    else
        __tmp=""
    fi
    printf -v "${__var}" '%s' "${__tmp}"
}


# ---------- 依赖安装 ----------
dep_install() {
    log "正在更新软件源并静默安装依赖，这可能需要一点时间..."
    apt-get update > /dev/null
    apt-get upgrade -y > /dev/null
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget openssl iptables iptables-persistent > /dev/null
    ok "依赖安装完成"
}


# ============================================================
#  检查 root 权限的函数
# ============================================================
check_root() {
    if [ $(id -u) != "0" ]; then
        die "请以 root 用户执行脚本！"
    fi
    if ! grep -qiE "debian|ubuntu" /etc/os-release; then
        die "本脚本仅支持 Debian/Ubuntu 系统！"
    fi
}


# ============================================================
#  安装主逻辑
# ============================================================
Install_Hy2() {
    # 检查服务是否存在
    if [[ -f "/etc/systemd/system/hysteria-server.service" ]]; then
        warn "检测到 Hysteria 2 服务已存在！"
        safe_read CONFIRM "是否覆盖安装？(y/n, 默认n): "
        CONFIRM=${CONFIRM:-n}
        if [[ "${CONFIRM}" != "y" ]]; then
            log "已取消安装。"
            return
        fi
    fi

    # 安装环境和依赖
    dep_install

    # ---------- 交互输入 ----------
    log "========== Hysteria 2 一键部署脚本 =========="

    # 1) 密码：用户自定义 或 自动生成 20 位
    safe_read user_pass "请输入密码（直接回车=自动生成20位强随机密码）: "
    if [[ -z "${user_pass}" ]]; then
        PASS="$(gen_pass_20)"
        ok "已生成随机密码：${PASS}"
    else
        PASS="${user_pass}"
        ok "使用用户提供的密码"
    fi

    # 2) 端口：选择 hysteria2 的监听端口并且验证合法性/是否被占用
    while true; do
        safe_read input_port "请输入 Hysteria 2 监听端口 (默认=443): "
        PORT=${input_port:-443}
        
        # 正则：必须全是数字
        if [[ ! "${PORT}" =~ ^[0-9]+$ ]] || [ "${PORT}" -lt 1 ] || [ "${PORT}" -gt 65535 ]; then
            warn "格式错误：端口必须是 1-65535 之间的纯数字！"
            continue
        fi

        # UDP 端口占用检查（Hysteria 2 走 UDP）
        if ss -uln | grep -qwE ":${PORT}"; then
            warn "端口冲突：UDP ${PORT} 已被其他程序占用！请重新输入。"
            continue
        fi
        
        ok "监听端口：${PORT}"
        break
    done

    # 3) 公网 IP：自动获取，允许用户覆盖
    log "正在获取公网 IPv4..."
    auto_ip="$(get_public_ipv4 2>/dev/null || true)"
    if [[ -n "${auto_ip}" ]]; then
        safe_read input_ip "检测到公网 IP：${auto_ip}，直接回车确认或输入覆盖: "
        HOST="${input_ip:-${auto_ip}}"
    else
        safe_read input_ip "自动获取 IP 失败，请手动输入服务器公网 IP: "
        [[ -z "${input_ip}" ]] && die "公网 IP 不能为空"
        HOST="${input_ip}"
    fi
    ok "服务器 IP：${HOST}"

    # 4) 伪装网站
    safe_read input_fake "请输入伪装网站 URL（默认=https://www.bing.com）: "
    FAKE_URL="${input_fake:-https://www.bing.com}"
    ok "伪装网站：${FAKE_URL}"

    # 5) 节点名称：用户输入 或 随机生成
    safe_read input_name "请输入节点名称（直接回车=自动生成）: "
    if [[ -z "${input_name}" ]]; then
        NODE_NAME="hy2-$(printf "%04d" $((RANDOM % 10000)))"
        ok "已生成随机节点名：${NODE_NAME}"
    else
        NODE_NAME="${input_name}"
        ok "使用用户提供的节点名：${NODE_NAME}"
    fi

    # 6) 端口跳跃及格式验证
    safe_read input_jump "是否启用 UDP 端口跳跃？（回车=启用 / 输入 n=不需要）: "
    input_jump="${input_jump:-y}"
    if [[ "${input_jump}" == "y" || "${input_jump}" == "Y" ]]; then
        while true; do
            safe_read input_mport "请输入 UDP 端口跳跃范围（默认=20000-20100）: "
            mport="${input_mport:-20000-20100}"
            
            # 正则：必须是 数字-数字 的格式
            if [[ ! "${mport}" =~ ^[0-9]+-[0-9]+$ ]]; then
                warn "格式错误：跳跃范围必须使用减号连接（例如 20000-20100）！"
                continue
            fi
            
            ENABLE_MPORT="yes"
            ok "将启用端口跳跃：${mport} -> ${PORT}"
            break
        done
    else
        ENABLE_MPORT="no"
        log "不启用端口跳跃"
    fi


    # ---------- 安装 Hysteria 2 ----------
    log "安装 Hysteria 2（官方脚本）..."
    bash <(curl -fsSL https://get.hy2.sh/) || die "Hysteria 2 官方安装脚本失败，请检查网络！"
    ok "Hysteria 2 安装完成"


    # ---------- 生成自签证书（CN=bing.com，100年） ----------
    log "生成自签证书（CN=bing.com，有效期100年）..."
    install -d -m 0755 /etc/hysteria

    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout /etc/hysteria/server.key \
        -out    /etc/hysteria/server.crt \
        -subj   "/CN=bing.com" \
        -days   36500 >/dev/null 2>&1

    if id -u hysteria >/dev/null 2>&1; then
        chown hysteria:hysteria /etc/hysteria/server.key /etc/hysteria/server.crt
    else
        chmod 600 /etc/hysteria/server.key
        chmod 644 /etc/hysteria/server.crt
    fi
    ok "证书生成完成：/etc/hysteria/server.crt  /etc/hysteria/server.key"


    # ---------- sysctl 网络优化 ----------
    log "写入 sysctl 优化：net.core.rmem_max=16777216..."
    cat > /etc/sysctl.d/99-hy2.conf <<'EOF'
net.core.rmem_max=16777216
EOF
    sysctl --system > /dev/null
    ok "sysctl 已生效"


    # ---------- 写入配置文件 ----------
    log "写入 /etc/hysteria/config.yaml..."
    cat > /etc/hysteria/config.yaml <<EOF
listen: :${PORT}

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: ${PASS}

masquerade:
  type: proxy
  proxy:
    url: ${FAKE_URL}
    rewriteHost: true

ignoreClientBandwidth: false
EOF
    ok "配置文件写入完成"


    # ---------- 端口跳跃 iptables 规则 ----------
    IFACE="$(get_default_iface || true)"
    [[ -n "${IFACE}" ]] && ok "检测到主网卡：${IFACE}" || warn "未能自动获取主网卡（不影响规则配置）"

    if [[ "${ENABLE_MPORT}" == "yes" ]]; then
        local ipt_range="$(echo "${mport}" | tr '-' ':')"
        log "配置 iptables：UDP ${mport} 重定向到 ${PORT}（NAT PREROUTING）..."
        if iptables -t nat -C PREROUTING -p udp --dport "${ipt_range}" -j REDIRECT --to-ports "${PORT}" >/dev/null 2>&1; then
            ok "iptables 规则已存在，跳过添加"
        else
            iptables -t nat -A PREROUTING -p udp --dport "${ipt_range}" -j REDIRECT --to-ports "${PORT}"
            ok "iptables 规则添加完成"
        fi

        log "持久化保存 iptables 规则..."
        if command -v netfilter-persistent >/dev/null 2>&1; then
            netfilter-persistent save > /dev/null
            ok "规则已持久化（netfilter-persistent）"
        elif [[ -d /etc/iptables ]]; then
            iptables-save > /etc/iptables/rules.v4
            ok "规则已保存到 /etc/iptables/rules.v4"
        else
            warn "未找到 netfilter-persistent 或 /etc/iptables，持久化可能失败"
        fi
    fi


    # ---------- 服务管理 ----------
    SERVICE_NAME="hysteria-server.service"
    SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

    if [[ ! -f "${SERVICE_PATH}" ]]; then
        if ! systemctl list-unit-files | grep -qE '^hysteria-server\.service'; then
            warn "未找到 ${SERVICE_PATH}，尝试列出相关 unit："
            systemctl list-unit-files | grep -E 'hysteria.*service' || true
            die "未检测到 hysteria-server.service，请确认官方安装脚本是否成功创建 systemd unit"
        fi
    fi

    log "设置 ${SERVICE_NAME} 开机自启并立即启动..."
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl restart "${SERVICE_NAME}" >/dev/null 2>&1 || true
    systemctl enable --now "${SERVICE_NAME}" >/dev/null

    if systemctl is-active --quiet "${SERVICE_NAME}"; then
        ok "${SERVICE_NAME} 服务已启动"
    else
        warn "${SERVICE_NAME} 未处于 active 状态，输出状态："
        systemctl status "${SERVICE_NAME}" --no-pager || true
        die "服务启动失败，请检查日志：journalctl -u ${SERVICE_NAME} -e --no-pager"
    fi


    # ---------- 生成客户端 URI ----------
    ENC_NODE="$(urlencode_fragment "${NODE_NAME}")"
    URI="hysteria2://${PASS}@${HOST}:${PORT}?sni=www.bing.com&insecure=1&allowInsecure=1"
    if [[ "${ENABLE_MPORT}" == "yes" ]]; then
        URI="${URI}&mport=${mport}#${ENC_NODE}"
    else
        URI="${URI}#${ENC_NODE}"
    fi

    echo
    echo -e "${GREEN}========== 部署完成 ==========${RESET}"
    echo -e "${YELLOW}请复制以下客户端连接 URI：${RESET}"
    echo -e "${GREEN}${URI}${RESET}"
    echo
    echo -e "${CYAN}提示：${RESET}因使用自签证书，链接已包含 insecure=1 / allowInsecure=1。"
    if [[ "${ENABLE_MPORT}" == "yes" ]]; then
        echo -e "${CYAN}提示：${RESET}已启用端口跳跃 mport=${mport}（UDP）-> ${PORT}。"
    fi
}


# ============================================================
#  卸载与环境清理
# ============================================================
Uninstall_Hy2() {
    local SERVICE="hysteria-server.service"

    echo
    log "========== Hysteria 2 卸载与环境清理 =========="

    # 1) 检查并停止服务
    log "检查 systemd 服务：${SERVICE} ..."
    if [[ -f "/etc/systemd/system/${SERVICE}" ]] || command -v hysteria >/dev/null 2>&1 || systemctl list-unit-files 2>/dev/null | grep -q "^${SERVICE}"; then
        if systemctl is-active --quiet "${SERVICE}" 2>/dev/null; then
            log "检测到服务正在运行，尝试停止..."
            systemctl stop "${SERVICE}" >/dev/null 2>&1 || true
            ok "服务已停止"
        else
            ok "检测到遗留的服务文件或程序，准备清理"
        fi

        log "调用官方卸载脚本（--remove）..."
        bash <(curl -fsSL https://get.hy2.sh/) --remove || true
        ok "基础服务文件已移除"
    else
        warn "未检测到 Hysteria 服务安装，跳过服务主体卸载步骤"
    fi

    # 2) 深度清理残余文件和用户
    log "清理配置文件、证书及内核优化残留..."
    rm -rf /etc/hysteria
    rm -f /etc/sysctl.d/99-hy2.conf
    sysctl --system >/dev/null 2>&1 || true
    if id -u hysteria >/dev/null 2>&1; then
        userdel -r hysteria >/dev/null 2>&1 || true
    fi
    ok "环境残留文件清理完成"

    # 3) 检查并清理 iptables 规则 (端口跳跃)
    log "检查 iptables NAT PREROUTING 规则..."
    if ! command -v iptables >/dev/null 2>&1; then
        warn "未找到 iptables，跳过防火墙规则检查"
    else
        local RULES
        RULES="$(iptables -t nat -L PREROUTING --line-numbers -n 2>/dev/null || true)"

        if echo "${RULES}" | awk 'BEGIN{has=0} $1 ~ /^[0-9]+$/ {has=1} END{exit (has?0:1)}'; then
            echo -e "${YELLOW}当前 NAT PREROUTING 规则如下（带行号）：${RESET}"
            echo "${RULES}"
            echo

            local DELNO=""
            safe_read DELNO "请输入要删除的规则行号（留空回车则默认不删除）："

            if [[ -z "${DELNO}" ]]; then
                warn "未输入行号，默认不删除任何规则"
            elif [[ ! "${DELNO}" =~ ^[0-9]+$ ]]; then
                warn "输入不是纯数字：${DELNO}，跳过删除"
            else
                if echo "${RULES}" | awk -v n="${DELNO}" '$1==n {found=1} END{exit(found?0:1)}'; then
                    log "正在删除规则：iptables -t nat -D PREROUTING ${DELNO}"
                    if iptables -t nat -D PREROUTING "${DELNO}" >/dev/null 2>&1; then
                        ok "规则已成功删除"
                        if command -v netfilter-persistent >/dev/null 2>&1; then
                            netfilter-persistent save >/dev/null 2>&1 || true
                            ok "已持久化保存（netfilter-persistent）"
                        else
                            warn "未找到 netfilter-persistent，需手动保存规则"
                        fi
                    else
                        warn "删除失败：行号可能已变化或规则不存在"
                    fi
                else
                    warn "未找到行号 ${DELNO} 对应的规则，跳过删除"
                fi
            fi
        else
            ok "未检测到 NAT PREROUTING 规则，跳过"
        fi
    fi

    echo
    ok "========== 环境清理与卸载流程结束 =========="
}


# ============================================================
#  入口：参数触发 或 菜单触发
# ============================================================
menu() {
    # 参数触发（适合自动化）：./hy2.sh --remove
    case "${1:-}" in
    --remove|--uninstall)
        Uninstall_Hy2
        exit 0
        ;;
    esac

    # 菜单触发（交互使用）
    log "欢迎使用由 Owen_W 开发的 Hysteria 2 一键部署脚本"
    log "================= 请选择操作 ================="
    echo "1) 安装 Hysteria 2"
    echo "2) 卸载/环境清理"
    safe_read CHOICE "请输入选项 [1-2]（默认1）："
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
    menu "$@"
}


# 执行主函数
main "$@"
