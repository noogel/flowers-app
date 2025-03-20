# Flowers App

一个基于 Flask 的鲜花展示应用，支持自动更新和容器化部署。

## 功能特性

- 基于 Flask 的 Web 应用
- 支持多平台 Docker 镜像构建
- 自动代码更新机制
- 支持代理配置
- 使用国内镜像源加速构建

## 环境要求

- Docker 20.10+
- Make
- Git

## 快速开始

### 1. 构建镜像

```bash
# 使用默认配置构建
make build

# 使用自定义代理构建
HTTP_PROXY=http://your-proxy:port HTTPS_PROXY=http://your-proxy:port make build

# 构建并推送到远程仓库
make push
```

### 2. 运行容器

```bash
docker run -d \
  -p 5000:5000 \
  -e GIT_REPO_URL=your-repo-url \
  -e GIT_BRANCH=main \
  -e AUTO_UPDATE=true \
  -e UPDATE_INTERVAL=3600 \
  your-image-name
```

## 环境变量配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| GIT_REPO_URL | Git 仓库地址 | 必填 |
| GIT_BRANCH | Git 分支 | main |
| GIT_REPO_PATH | 应用目录 | /app/flowers-app |
| AUTO_UPDATE | 是否启用自动更新 | true |
| UPDATE_INTERVAL | 更新间隔（秒） | 3600 |
| HTTP_PROXY | HTTP 代理 | 可选 |
| HTTPS_PROXY | HTTPS 代理 | 可选 |
| NO_PROXY | 不使用代理的地址 | localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12 |

## 项目结构

```
flowers-app/
├── app.py              # 主应用文件
├── requirements.txt    # Python 依赖
├── templates/         # HTML 模板
├── static/           # 静态文件
├── Dockerfile        # Docker 构建文件
└── Makefile         # 构建脚本
```

## 构建说明

### 多平台支持

支持以下平台：
- linux/amd64
- linux/arm64

### 镜像源配置

- apt: 使用清华大学镜像源
- pip: 使用清华大学镜像源

### 自动更新机制

1. 容器启动时自动拉取最新代码
2. 如果拉取失败，使用本地文件继续运行
3. 支持定时检查更新（默认每小时）
4. 只更新必要的应用文件

## 开发说明

### 本地开发

```bash
# 安装依赖
pip install -r requirements.txt

# 运行应用
flask run
```

### 构建测试

```bash
# 查看环境配置
make env

# 清理构建缓存
make clean

# 构建测试
make build
```

## 注意事项

1. 确保 Docker 已启用 BuildKit
2. 如果使用代理，请正确配置 NO_PROXY 环境变量
3. 自动更新失败时会使用本地文件继续运行
4. 建议定期清理构建缓存

## 许可证

Apache 2.0 License