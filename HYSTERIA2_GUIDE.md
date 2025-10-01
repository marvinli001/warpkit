# Hysteria V2 管理功能使用指南

## 概述

Hysteria V2 是基于 QUIC 协议的新一代代理工具，具有高性能、低延迟的特点。WarpKit 提供了完整的 Hysteria V2 管理功能，包括引导式安装、服务管理和配置管理。

## 功能特性

### ✨ 主要功能

1. **智能状态检测**
   - 自动检测 Hysteria V2 安装状态
   - 实时显示服务运行状态
   - 显示开机自启配置状态
   - 显示版本信息

2. **两种安装模式**
   - **引导式安装**: 交互式配置向导，适合自定义配置
   - **快速安装**: 使用默认配置快速部署，适合快速测试

3. **完整的服务管理**
   - 启动/停止/重启服务
   - 开机自启管理（启用/禁用）
   - 查看服务状态和日志
   - 配置文件编辑

4. **配置信息管理**
   - 自动保存连接信息
   - 随时查看配置详情
   - 安全的密码生成

5. **完整的卸载功能**
   - 清理所有相关文件
   - 停止服务并移除

## 使用流程

### 📋 第一次使用

#### 1. 进入 Hysteria V2 管理器

```bash
# 方式1: 从主菜单
./warpkit.sh
# 选择 "6. 软件管理" -> "2. Hysteria V2"

# 方式2: 直接访问
./warpkit.sh --software
# 然后选择 "2. Hysteria V2"
```

#### 2. 查看状态信息

首次进入会显示：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠ Hysteria V2 未安装
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 🚀 引导式安装

推荐首次使用者选择引导式安装，可以自定义所有配置。

#### 配置步骤

**[1/6] 配置监听端口**
- 默认: `443`
- 建议: 使用 443 或 8443

**[2/6] 配置认证密码**
- 可以自定义或留空自动生成
- 自动生成的密码为 16 位随机字符串

**[3/6] 是否启用混淆**
- 混淆可以提高隐蔽性
- 推荐启用（输入 `y`）
- 混淆密码可自定义或自动生成

**[4/6] TLS 证书配置**
- **选项 1**: 自签名证书（推荐用于测试）
  - 自动生成自签名证书
  - 无需域名
  - 适合快速部署

- **选项 2**: Let's Encrypt 证书（推荐用于生产）
  - 需要有效域名
  - 需要邮箱地址
  - 自动申请和续期证书

**[5/6] 带宽限制（可选）**
- 可以设置上传和下载速度限制
- 格式: `100 mbps` 或 `1 gbps`
- 默认: 不限制（`1 gbps`）

**[6/6] 配置确认**
- 显示所有配置的摘要
- 确认后开始安装

#### 安装过程

```
开始安装 Hysteria V2...
✓ Hysteria V2 安装完成
正在生成配置文件...
✓ 配置文件已生成: /etc/hysteria/config.yaml
正在启动服务...
✓ Hysteria V2 服务已启动
```

#### 连接信息

安装完成后会显示连接信息：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Hysteria V2 连接信息
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

服务器地址: xxx.xxx.xxx.xxx
监听端口: 443
认证密码: ****************
混淆密码: ****************

连接信息已保存到: /usr/local/warpkit/data/software/hysteria2_info.txt
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ⚡ 快速安装

适合快速测试和部署，使用默认配置。

**默认配置:**
- 监听端口: `443`
- 认证方式: 密码认证（随机生成）
- TLS: 自签名证书
- 混淆: 未启用

确认后直接安装，无需配置。

## 管理功能

### 📊 查看服务状态

显示详细的服务状态信息：
- 服务运行状态
- 进程信息
- 资源使用情况
- 启动时间

### 🔧 服务管理

**启动服务**
```bash
systemctl start hysteria-server.service
```

**停止服务**
```bash
systemctl stop hysteria-server.service
```

**重启服务**
```bash
systemctl restart hysteria-server.service
```

所有操作都有状态反馈和错误提示。

### 🔄 开机自启管理

**启用开机自启**
```bash
systemctl enable hysteria-server.service
```

**禁用开机自启**
```bash
systemctl disable hysteria-server.service
```

当前状态会实时显示在主界面。

### 📝 查看配置信息

有两种方式查看配置：

1. **查看已保存的连接信息**
   - 显示服务器地址、端口、密码等
   - 路径: `/usr/local/warpkit/data/software/hysteria2_info.txt`

2. **查看完整配置文件**
   - 显示 `/etc/hysteria/config.yaml` 的完整内容
   - 包含所有高级配置选项

### ✏️ 编辑配置文件

支持使用编辑器修改配置：
- 优先使用 `nano` 编辑器
- 如果 nano 不可用，使用 `vi`
- 修改后可以立即重启服务使配置生效

**配置文件路径**: `/etc/hysteria/config.yaml`

### 📜 查看日志

显示最近 50 条服务日志：
```bash
journalctl -u hysteria-server.service -n 50
```

日志包含：
- 服务启动信息
- 连接日志
- 错误信息
- 性能统计

### 🗑️ 卸载 Hysteria V2

完整的卸载流程：

1. 显示警告信息
2. 要求用户确认
3. 停止并禁用服务
4. 删除程序文件
5. 删除配置目录
6. 清理保存的信息

**被删除的文件:**
- `/usr/local/bin/hysteria`
- `/etc/systemd/system/hysteria-server.service`
- `/etc/hysteria/` (整个目录)
- 保存的连接信息

## 配置文件详解

### 基本结构

```yaml
# Hysteria V2 服务端配置
# 由 WarpKit 自动生成

listen: :443

# TLS 配置
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

# 认证配置
auth:
  type: password
  password: your_password

# 混淆配置（可选）
obfs:
  type: salamander
  salamander:
    password: your_obfs_password

# 带宽配置
bandwidth:
  up: 1 gbps
  down: 1 gbps

# QUIC 优化配置
quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 33554432

ignoreClientBandwidth: false
disableUDP: false
udpIdleTimeout: 60s
```

### 配置项说明

#### listen
监听地址和端口
- 格式: `:端口号`
- 示例: `:443` (监听所有接口的 443 端口)

#### tls
TLS/SSL 证书配置

**自签名证书:**
```yaml
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
```

**ACME 自动证书:**
```yaml
acme:
  domains:
    - yourdomain.com
  email: your@email.com
```

#### auth
认证配置
```yaml
auth:
  type: password
  password: your_strong_password
```

#### obfs (可选)
混淆配置，提高隐蔽性
```yaml
obfs:
  type: salamander
  salamander:
    password: your_obfs_password
```

#### bandwidth (可选)
带宽限制
```yaml
bandwidth:
  up: 1 gbps    # 上传速度
  down: 1 gbps  # 下载速度
```

支持的单位:
- `bps` - 比特每秒
- `kbps` - 千比特每秒
- `mbps` - 兆比特每秒
- `gbps` - 吉比特每秒

#### quic
QUIC 协议优化参数
- `initStreamReceiveWindow`: 初始流接收窗口
- `maxStreamReceiveWindow`: 最大流接收窗口
- `initConnReceiveWindow`: 初始连接接收窗口
- `maxConnReceiveWindow`: 最大连接接收窗口

默认值已经过优化，一般无需修改。

## 客户端配置

### 基本信息

您需要以下信息来配置客户端：
- 服务器地址（IP 或域名）
- 监听端口
- 认证密码
- 混淆密码（如果启用）
- TLS 设置（跳过证书验证或使用域名）

### 客户端配置示例

#### Hysteria2 原生客户端

```yaml
server: your_server_ip:443
auth: your_password

tls:
  insecure: true  # 使用自签名证书时需要

# 如果启用了混淆
obfs:
  type: salamander
  salamander:
    password: your_obfs_password

bandwidth:
  up: 50 mbps
  down: 100 mbps
```

#### Clash Meta / Clash Premium

```yaml
proxies:
  - name: Hysteria2
    type: hysteria2
    server: your_server_ip
    port: 443
    password: your_password
    skip-cert-verify: true

    # 如果启用了混淆
    obfs: salamander
    obfs-password: your_obfs_password
```

## 常见问题

### Q1: 服务无法启动？

**检查步骤:**
1. 查看日志: 选择"查看日志"选项
2. 检查配置文件语法
3. 确认端口未被占用
4. 检查防火墙设置

### Q2: 客户端无法连接？

**排查步骤:**
1. 确认服务正在运行
2. 检查防火墙是否放行端口
3. 验证客户端配置信息是否正确
4. 如使用自签名证书，确保客户端跳过证书验证

### Q3: 如何修改配置？

两种方式：
1. 使用"编辑配置文件"功能
2. 手动编辑 `/etc/hysteria/config.yaml`

修改后记得重启服务！

### Q4: 忘记了连接密码？

查看保存的信息：
1. 选择"查看配置信息"
2. 或查看文件: `/usr/local/warpkit/data/software/hysteria2_info.txt`

### Q5: 如何更换证书？

**自签名证书 -> Let's Encrypt:**
1. 编辑配置文件
2. 将 `tls` 部分替换为 `acme` 配置
3. 重启服务

**Let's Encrypt -> 自签名:**
1. 生成新的自签名证书
2. 编辑配置文件，使用 `tls` 配置
3. 重启服务

## 安全建议

### 🔒 增强安全性

1. **使用强密码**
   - 至少 16 位
   - 包含大小写字母、数字和特殊字符
   - 或使用自动生成的随机密码

2. **启用混淆**
   - 提高隐蔽性
   - 避免流量特征被识别

3. **使用非标准端口**
   - 不要使用默认的 443
   - 选择 10000-65535 之间的随机端口

4. **配置防火墙**
   - 只开放必要的端口
   - 限制 SSH 访问

5. **使用有效证书**
   - 生产环境推荐使用 Let's Encrypt
   - 避免证书验证被中间人攻击

6. **定期查看日志**
   - 监控异常连接
   - 及时发现安全问题

### 🛡️ 防火墙配置

**UFW (Ubuntu/Debian):**
```bash
ufw allow 443/udp
ufw reload
```

**firewalld (CentOS/RHEL):**
```bash
firewall-cmd --permanent --add-port=443/udp
firewall-cmd --reload
```

## 文件位置

### 程序文件
- **可执行文件**: `/usr/local/bin/hysteria`
- **服务文件**: `/etc/systemd/system/hysteria-server.service`

### 配置文件
- **主配置**: `/etc/hysteria/config.yaml`
- **证书文件**: `/etc/hysteria/server.crt` (自签名)
- **私钥文件**: `/etc/hysteria/server.key` (自签名)

### 数据文件
- **连接信息**: `/usr/local/warpkit/data/software/hysteria2_info.txt`
- **安装日志**: 由 systemd 管理

### 日志位置
使用 journalctl 查看:
```bash
journalctl -u hysteria-server.service -f  # 实时查看
journalctl -u hysteria-server.service -n 100  # 最近100条
```

## 性能优化

### 系统优化

**增加文件描述符限制:**
```bash
# /etc/security/limits.conf
* soft nofile 51200
* hard nofile 51200
```

**优化内核参数:**
```bash
# /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
```

应用配置:
```bash
sysctl -p
```

### 带宽配置建议

根据服务器实际带宽设置：
- **100 Mbps 服务器**: `up: 80 mbps, down: 80 mbps`
- **1 Gbps 服务器**: `up: 800 mbps, down: 800 mbps`
- **10 Gbps 服务器**: `up: 8 gbps, down: 8 gbps`

留 20% 的余量给系统和其他服务。

## 技术支持

### 相关链接
- **Hysteria 官方文档**: https://v2.hysteria.network/
- **GitHub 仓库**: https://github.com/apernet/hysteria
- **WarpKit 项目**: https://github.com/marvinli001/warpkit

### 获取帮助
1. 查看 Hysteria 官方文档
2. 检查服务日志
3. 在 GitHub 提交 Issue

---

**文档版本**: 1.0
**更新时间**: 2025-10-01
**适用版本**: WarpKit v1.1+
