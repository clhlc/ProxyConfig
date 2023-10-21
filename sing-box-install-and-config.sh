#!/bin/bash

server_ip=$(curl -s https://api.ipify.org)
uuid=$(/usr/bin/sing-box generate uuid)

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
    echo -e "{\n\n}" > /usr/local/etc/sing-box/config.json
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
}

function restart() {
    systemctl restart sing-box.service
}

function vless_reality() {
    key_pair=$(/usr/bin/sing-box generate reality-keypair)

    private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')

    public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')

    short_id=$(/usr/bin/sing-box generate rand --hex 8)
    
    port=$((RANDOM % 1001 + 10000))

    wget -O /usr/local/etc/sing-box/vless_reality.json https://raw.githubusercontent.com/clhlc/ProxyConfig/main/Sing-Box/VLESS-XTLS-uTLS-REALITY/config.json

    sed -i "s/PORT/$port/g; s/UUID/$uuid/g; s/SERVER_NAME/gateway\.icloud\.com/g; s/SERVER/gateway\.icloud\.com/g; s/PRIVATE_KEY/$private_key/g; s/SHORT_ID/$short_id/g" /usr/local/etc/sing-box/vless_reality.json

    server_link="vless://$uuid@$server_ip:$port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=gateway.icloud.com&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#Sing-Box-Reality"

    echo "Link: $server_link"

    restart
}

function hy2() {
    password=$(LC_ALL=C tr -dc 'a-zA-Z0-9!@#$%^&*_+=' < /dev/urandom | fold -w 16 | head -n 1)

    mkdir -p /etc/hysteria && openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/private.key && openssl req -new -x509 -days 3650 -key /etc/hysteria/private.key -out /etc/hysteria/cert.pem -subj "/CN=bing.com"

    wget -O /usr/local/etc/sing-box/hy2.json https://raw.githubusercontent.com/clhlc/ProxyConfig/main/Sing-Box/Hysteria2/config.json

    sed -i "s/PASSWORD/$password/g" /usr/local/etc/sing-box/hy2.json

    cat /usr/local/etc/sing-box/hy2.json

    echo "Link: hysteria2://$password@$server_ip:10003?insecure=1&obfs=none#Hysteria2-UDP"

    restart
}

function shadowtls() {
    password=$(/usr/bin/sing-box  generate  rand --base64 32)

    wget -O /usr/local/etc/sing-box/shadowtls.json https://raw.githubusercontent.com/clhlc/ProxyConfig/main/Sing-Box/ShadowTLS/config.json

    sed -i "s/PASSWORD/$password/g" /usr/local/etc/sing-box/shadowtls.json

    cat /usr/local/etc/sing-box/shadowtls.json

    restart
}