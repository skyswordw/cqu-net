# CQU-NET 自动登录工具

这是一个重庆大学校园网自动登录工具，每30秒检测一次网络状态，在断网时自动重新登录。

## 使用方法

### 方式一：使用预构建镜像（推荐）

直接使用 GitHub Container Registry 上的预构建镜像：

```bash
docker run -d \
  -e USER_ACCOUNT="你的学号" \
  -e USER_PASSWORD="你的密码" \
  -e USER_MAC="你的MAC地址" \
  --name cqu-net \
  --restart always \
  ghcr.io/skyswordw/cqu-net:latest
```

### 方式二：本地构建

1. 首先构建Docker镜像：
```bash
docker build -t cqu-net .
```

2. 运行容器（请替换下面的环境变量）：
```bash
docker run -d \
  -e USER_ACCOUNT="你的学号" \
  -e USER_PASSWORD="你的密码" \
  -e USER_MAC="你的MAC地址" \
  --name cqu-net \
  --restart always \
  cqu-net
```

### 环境变量说明
- USER_ACCOUNT: 你的学号
- USER_PASSWORD: 你的密码
- USER_MAC: 你的设备MAC地址（格式示例：3ac47ff39813）

### 如何获取MAC地址
- Windows: 在命令提示符中输入 `ipconfig /all` 查看"物理地址"
- macOS: 在终端中输入 `ifconfig en0 | grep ether` 查看
- Linux: 在终端中输入 `ip link` 或 `ifconfig` 查看

注意：MAC地址需要去掉冒号或连字符，例如 `3a:c4:7f:f3:98:13` 应该输入为 `3ac47ff39813`

## 查看日志
```bash
docker logs -f cqu-net
```

## 停止服务
```bash
docker stop cqu-net
```

## 启动服务
```bash
docker start cqu-net
```

## 版本发布

本项目使用 GitHub Actions 自动构建和发布 Docker 镜像。每次推送到 main 分支或创建新的标签（tag）时，都会自动构建新的镜像。

- main 分支的最新代码会被标记为 `latest`
- 发布标签（如 v1.0.0）会生成对应版本号的镜像标签

如果你想使用特定版本的镜像，可以在运行时指定版本号，例如：
```bash
docker run ... ghcr.io/你的GitHub用户名/cqu-net:v1.0.0
```

## 未来开发计划 (TODO)

### 可配置的环境变量
计划添加以下环境变量支持：
- `GATEWAY_IP`: 登录网关IP地址（默认：10.254.7.4）
- `CHECK_INTERVAL`: 网络检测间隔时间（默认：30秒）
- `USER_AGENT_TYPE`: 用户代理类型，可选值：
  - `mac`: macOS设备
  - `windows`: Windows设备
  - `linux`: Linux设备
  - `custom`: 自定义UA（需配合 `CUSTOM_USER_AGENT` 使用）
- `CUSTOM_USER_AGENT`: 自定义User-Agent字符串

### 功能优化
- 支持自定义网络检测目标（默认为 www.baidu.com）
- 优化重试策略：
  - 支持配置短时间内最大重试次数
  - 添加指数退避算法，避免频繁重试
  - 在登录失败时解析响应内容，提供更详细的错误信息
- 添加登录状态检测（通过解析登录接口返回信息）
- 支持日志级别配置
- 添加登录成功/失败通知机制 