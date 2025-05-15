# Proxy Config
基于Sing-box搭建的代理服务器节点，支持Hysteria2/Vless Reality/ShadowTLS/Tuic.

## 端口
协议|端口
---|---
Hysteria2|10003
Vless Reality|10004
ShadowTLS|10005
Anytls|10006
Tuic|443

在各个云厂商的防火墙或者安全组需要对公网开放端口

## 使用
```shell
bash <(wget -qO- https://raw.githubusercontent.com/clhlc/ProxyConfig/main/sing-box-install-and-config.sh)
```
```shell
#############################################################
#               Sing-Box 一键安装脚本                       #
# 作者: clhlc                                               #
# GitHub 项目: https://github.com/clhlc/ProxyConfig         #
#############################################################

 0. 初始化 VPS
 1. 安装 Sing-Box
 2. 卸载 Sing-Box
 3. 重启 Sing-Box
 4. 查看 Sing-Box 日志
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 11. 配置 Hysteria2(推荐)
 12. 配置 Vless+XTLS+uTLS+Reality(推荐)
 13. 配置 SS+ShadowTLS
 14. 配置 Tuic V5
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 10. 退出脚本
