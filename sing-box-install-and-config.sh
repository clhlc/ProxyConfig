#!/bin/bash
export LANG=en_US.UTF-8

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

function common_command() {
    server_ip=$(curl -s https://api.ipify.org)
    uuid=$(/usr/bin/sing-box generate uuid)
    password=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 16 | head -n 1)
}

function check_config_exit() {
    conf_file="/usr/local/etc/sing-box/$1.json"
    if [[ -e $conf_file ]]; then
        yellow "配置文件已存在，重新配置请删除: $conf_file"
        exit 1
    fi
}

function check_config_validate() {
    conf_file="/usr/local/etc/sing-box/$1.json"

    /usr/bin/sing-box check -c $conf_file

    if [[ $? != 0 ]]; then
        red 配置文件不正确，请检查: $conf_file。
        exit 2
    fi
}

function install_sing_box() {
    latest_version_tag=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep -Po '"tag_name": "\K.*?(?=")' | head -n 1)
    latest_version=${latest_version_tag#v}
    echo "Latest version: $latest_version"

    arch=$(uname -m)
    echo "Architecture: $arch"

    case ${arch} in
    x86_64)
        arch="amd64"
        ;;
    aarch64)
        arch="arm64"
        ;;
    armv7l)
        arch="armv7"
        ;;
    esac

    package_name="sing-box-${latest_version}-linux-${arch}"

    url="https://github.com/SagerNet/sing-box/releases/download/${latest_version_tag}/${package_name}.tar.gz"

    curl -sLo "/tmp/${package_name}.tar.gz" "$url"

    tar -xzf "/tmp/${package_name}.tar.gz" -C /tmp
    mv "/tmp/${package_name}/sing-box" /usr/bin/sing-box

    rm -r "/tmp/${package_name}.tar.gz" "/tmp/${package_name}"

    chown root:root /usr/bin/sing-box
    chmod +x /usr/bin/sing-box

    mkdir -p /usr/local/etc/sing-box
    echo -e "{\n\n}" >/usr/local/etc/sing-box/config.json
    echo "[Unit]
    Description=sing-box service
    Documentation=https://sing-box.sagernet.org
    After=network.target nss-lookup.target

    [Service]
    CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
    AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
    ExecStart=/usr/bin/sing-box -C /usr/local/etc/sing-box run
    ExecReload=/bin/kill -HUP $MAINPID
    Restart=on-failure
    RestartSec=10s
    LimitNOFILE=infinity

    [Install]
    WantedBy=multi-user.target" | tee /etc/systemd/system/sing-box.service
    systemctl daemon-reload

    green 安装sing-box完成！
}

function restart() {
    systemctl restart sing-box.service
    sleep 2
    systemctl status sing-box.service --no-pager -l
}

function vless_reality() {

    conf_name="vless_reality"
    check_config_exit $conf_name
    common_command

    key_pair=$(/usr/bin/sing-box generate reality-keypair)

    private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')

    public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')

    short_id=$(/usr/bin/sing-box generate rand --hex 8)

    port=$((RANDOM % 1001 + 10000))

    wget -O /usr/local/etc/sing-box/$conf_name.json https://raw.githubusercontent.com/clhlc/ProxyConfig/main/Sing-Box/VLESS-XTLS-uTLS-REALITY/config.json

    sed -i "s/PORT/$port/g; s/UUID/$uuid/g; s/SERVER_NAME/gateway\.icloud\.com/g; s/SERVER/gateway\.icloud\.com/g; s/PRIVATE_KEY/$private_key/g; s/SHORT_ID/$short_id/g" /usr/local/etc/sing-box/$conf_name.json

    server_link="vless://$uuid@$server_ip:$port?security=reality&flow=xtls-rprx-vision&sni=gateway.icloud.com&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#Sing-Box-Reality"

    red "Link: $server_link"

    check_config_validate $conf_name
    restart
}

function hy2() {

    conf_name="hy2"
    check_config_exit $conf_name
    common_command
    sni="bing.com"
    masquerade="https:\/\/bing.com"

    mkdir -p /etc/hysteria && openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/private.key && openssl req -new -x509 -days 3650 -key /etc/hysteria/private.key -out /etc/hysteria/cert.pem -subj "/CN=bing.com"

    wget -O /usr/local/etc/sing-box/$conf_name.json https://raw.githubusercontent.com/clhlc/ProxyConfig/main/Sing-Box/Hysteria2/config.json

    sed -i "s/PASSWORD/$password/g; s/SNI/$masquerade/g" /usr/local/etc/sing-box/$conf_name.json

    cat /usr/local/etc/sing-box/$conf_name.json

    echo "====================================="

    red "Link: hysteria2://$password@$server_ip:10003?insecure=1&obfs=none&peer=$peer#Hysteria2($server_ip)"

    green "二维码"

    qrencode -o - -t ANSIUTF8 "hysteria2://$password@$server_ip:10003?insecure=1&obfs=none&sni=$sni#Hysteria2($server_ip)"

    check_config_validate $conf_name
    restart
}

function shadowtls() {

    conf_name="shadowtls"

    check_config_exit $conf_name

    shadowtls_password=$(/usr/bin/sing-box generate rand --base64 32)

    wget -O /usr/local/etc/sing-box/$conf_name.json https://raw.githubusercontent.com/clhlc/ProxyConfig/main/Sing-Box/ShadowTLS/config.json

    sed -i "s/PASSWORD/$shadowtls_password/g" /usr/local/etc/sing-box/$conf_name.json

    cat /usr/local/etc/sing-box/$conf_name.json

    check_config_validate $conf_name
    restart
}

function test() {
    green "begin"
    check_config_exit test
    green "end"
}

function tuic-v5() {

    conf_name="tuic-v5"

    common_command $conf_name
    check_config_exit $conf_name

    wget -O /usr/local/etc/sing-box/$conf_name.json https://raw.githubusercontent.com/clhlc/ProxyConfig/main/Sing-Box/TUIC/config.json

    sed -i "s/PASSWORD/$password/g" /usr/local/etc/sing-box/$conf_name
    sed -i "s/UUID/$uuid/g" /usr/local/etc/sing-box/$conf_name

    check_config_validate $conf_name
    restart
}

menu() {
    clear
    echo "#############################################################"
    echo -e "#               ${RED}Sing-Box 一键安装脚本${PLAIN}                       #"
    echo -e "# ${GREEN}作者${PLAIN}: clhlc                                               #"
    echo -e "# ${GREEN}GitHub 项目${PLAIN}: https://github.com/clhlc/ProxyConfig         #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 安装 Sing-Box"
    echo -e " ${GREEN}2.${PLAIN} 配置 Vless+XTLS+uTLS+Reality"
    echo -e " ${GREEN}3.${PLAIN} 配置 Hysteria2"
    echo -e " ${GREEN}4.${PLAIN} 配置 ShadowTLS"
    echo -e " ${GREEN}5.${PLAIN} 配置 Tuic V5"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    echo ""
    read -rp "请输入选项 [0-7]: " menuInput
    case $menuInput in
    1) install_sing_box ;;
    2) vless_reality ;;
    3) hy2 ;;
    4) shadowtls ;;
    5) tuic ;;
    99) test ;;
    *) exit 1 ;;
    esac
}

menu
