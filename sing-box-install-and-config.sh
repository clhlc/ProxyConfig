#!/bin/bash
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
sudo mv "/tmp/${package_name}/sing-box" /usr/bin/sing-box

rm -r "/tmp/${package_name}.tar.gz" "/tmp/${package_name}"

sudo chown root:root /usr/bin/sing-box
sudo chmod +x /usr/bin/sing-box

sudo mkdir -p /usr/local/etc/sing-box
sudo wget https://github.com/SagerNet/sing-box/raw/main/release/config/config.json -O /usr/local/etc/sing-box/config.json
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
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/sing-box.service
sudo systemctl daemon-reload

function vless_reality () {
    
}