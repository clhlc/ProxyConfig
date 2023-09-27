# Cloudflare Warp Install

## Install

```shell
# 安装Warp-cli GPG密钥：
curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

# 添加Warp-cli源：
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# 更新APT缓存：
apt update

# 安装Warp-cli：
apt install cloudflare-warp

# 注册WARP：
warp-cli register

# 设置为Socks代理模式(十分重要,如果直接连接会导致shell失联)：
warp-cli set-mode proxy

# 连接Warp-cli：
warp-cli connect

# 查询代理后的IP地址：
curl ifconfig.me --proxy socks5://127.0.0.1:40000
```

## Team
```shell
warp-cli teams-enroll [你的团队域]

warp-cli teams-enroll-token com.cloudflare.warp://[team-domain].cloudflareaccess.com/auth?token=[token]
```

## 其他

### Token获取

### 改变Team的代理模式