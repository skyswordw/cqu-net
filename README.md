# CQU-NET 自动登录工具

这是一个重庆大学校园网自动登录工具，定期检测网络状态（默认每5秒），在断网时自动重新登录。

## 使用方法

### 方式一：使用预构建镜像

#### 使用 Docker Compose 运行（适用于 1Panel、Dockge、Portainer 等面板）

下面是一个带有详细注释的 docker-compose 配置示例：

```yaml
version: '3.9'
services:
  cqu-net:
    image: ghcr.io/skyswordw/cqu-net:latest    # 使用最新版本的镜像
    container_name: cqu-net                     # 容器名称
    restart: always                             # 容器自动重启策略
    environment:
      - ACCOUNT=${ACCOUNT}                     # 你的学号/工号
      - PASSWORD=${PASSWORD}                   # 你的密码
      - TERM_TYPE=${TERM_TYPE:-pc}             # (可选) 登录设备类型, pc 或 android, 默认 pc
      - LOG_LEVEL=${LOG_LEVEL:-info}           # (可选) 日志级别, info 或 debug, 默认 info
      - INTERVAL=${INTERVAL:-5}                # (可选) 检测间隔时间（秒）, 默认 5
```

在容器管理面板中需要配置的环境变量：
```plaintext
ACCOUNT=你的学号或工号
PASSWORD=你的密码
# TERM_TYPE=pc      # 可选, 默认是 pc, 如需模拟手机登录可改为 android
# LOG_LEVEL=info    # 可选, 默认是 info, 如需调试可改为 debug
# INTERVAL=5        # 可选, 默认是 5 秒
```

部署步骤：
1. 在面板中创建新的应用/堆栈：
   - 1Panel：在"应用管理"中选择"自定义安装"
   - Dockge：创建新的 Stack
   - Portainer：在"Stacks"中创建新的 stack

2. 将上述 docker-compose 配置复制到编辑器中

3. 在环境变量配置部分填入你的个人信息 (ACCOUNT 和 PASSWORD 是必需的)

4. 点击部署即可

#### 使用 Docker 命令运行

```bash
docker run -d \
  -e ACCOUNT="你的学号或工号" \
  -e PASSWORD="你的密码" \
  # -e TERM_TYPE="pc" \
  # -e LOG_LEVEL="info" \
  # -e INTERVAL="5" \
  --name cqu-net \
  --restart always \
  ghcr.io/skyswordw/cqu-net:latest
```

### 方式二：本地构建

适合需要自定义修改或本地开发的用户：

1. 首先构建Docker镜像：
```bash
docker build -t cqu-net .
```

2. 运行容器（请替换下面的环境变量）：
```bash
docker run -d \
  -e ACCOUNT="你的学号或工号" \
  -e PASSWORD="你的密码" \
  # -e TERM_TYPE="pc" \
  # -e LOG_LEVEL="info" \
  # -e INTERVAL="5" \
  --name cqu-net \
  --restart always \
  cqu-net
```

### 环境变量说明
- `ACCOUNT`: **必需**, 你的学号或工号
- `PASSWORD`: **必需**, 你的密码
- `TERM_TYPE`: (可选) 登录模拟的设备类型，可选值为 `pc` 或 `android`。默认为 `pc`。
- `LOG_LEVEL`: (可选) 输出日志的级别，可选值为 `info` 或 `debug`。默认为 `info`。
- `INTERVAL`: (可选) 网络连接检测间隔时间，单位为秒。默认为 `5`。

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
docker run ... ghcr.io/skyswordw/cqu-net:v1.0.0