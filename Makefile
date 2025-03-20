# 加载 .env 文件
include .env
export

# Docker Hub 用户名
DOCKER_USERNAME ?= noogel
# 本地仓库地址
REGISTRY ?= registry-1.docker.io
# Docker 镜像名称
IMAGE_NAME = $(REGISTRY)/$(DOCKER_USERNAME)/flowers-app
# 镜像标签
TAG = latest
# 支持的平台
PLATFORMS = linux/amd64 linux/arm64
# 代理设置
HTTP_PROXY ?= http://127.0.0.1:7890
HTTPS_PROXY ?= http://127.0.0.1:7890
NO_PROXY ?= localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12

.PHONY: build push clean setup env

# 显示环境变量
env:
	@echo "当前环境变量配置："
	@echo "DOCKER_USERNAME: $(DOCKER_USERNAME)"
	@echo "REGISTRY: $(REGISTRY)"
	@echo "IMAGE_NAME: $(IMAGE_NAME)"
	@echo "TAG: $(TAG)"
	@echo "PLATFORMS: $(PLATFORMS)"
	@echo "HTTP_PROXY: $(HTTP_PROXY)"
	@echo "HTTPS_PROXY: $(HTTPS_PROXY)"
	@echo "NO_PROXY: $(NO_PROXY)"
	@echo "GIT_REPO_URL: $(GIT_REPO_URL)"
	@echo "GIT_BRANCH: $(GIT_BRANCH)"
	@echo "GIT_REPO_PATH: $(GIT_REPO_PATH)"
	@echo "AUTO_UPDATE: $(AUTO_UPDATE)"
	@echo "UPDATE_INTERVAL: $(UPDATE_INTERVAL)"

# 设置 Docker 配置
setup:
	@if [ -f ~/.docker/config.json ]; then \
		jq '. + {"insecure-registries": ["$(REGISTRY)"]}' ~/.docker/config.json > ~/.docker/config.json.tmp && mv ~/.docker/config.json.tmp ~/.docker/config.json; \
	else \
		echo '{"insecure-registries": ["$(REGISTRY)"]}' > ~/.docker/config.json; \
	fi
	@echo "已配置不安全仓库: $(REGISTRY)"

# 构建多平台镜像
build: setup
	docker buildx create --name multiarch-builder --use || true
	docker buildx inspect --bootstrap
	@for platform in $(PLATFORMS); do \
		platform_tag=$$(echo $$platform | tr '/' '-'); \
		echo "Building for platform: $$platform (tag: $$platform_tag)"; \
		docker buildx build --platform $$platform \
			--build-arg HTTP_PROXY=$(HTTP_PROXY) \
			--build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
			--build-arg NO_PROXY=$(NO_PROXY) \
			--build-arg GIT_REPO_URL=$(GIT_REPO_URL) \
			--build-arg GIT_BRANCH=$(GIT_BRANCH) \
			--build-arg GIT_REPO_PATH=$(GIT_REPO_PATH) \
			--build-arg AUTO_UPDATE=$(AUTO_UPDATE) \
			--build-arg UPDATE_INTERVAL=$(UPDATE_INTERVAL) \
			-t $(IMAGE_NAME):$(TAG)-$$platform_tag \
			--load \
			.; \
	done

# 推送镜像到仓库
push: setup
	docker buildx create --name multiarch-builder --use || true
	docker buildx inspect --bootstrap
	@for platform in $(PLATFORMS); do \
		platform_tag=$$(echo $$platform | tr '/' '-'); \
		echo "Building for platform: $$platform (tag: $$platform_tag)"; \
		docker buildx build --platform $$platform \
			--build-arg HTTP_PROXY=$(HTTP_PROXY) \
			--build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
			--build-arg NO_PROXY=$(NO_PROXY) \
			--build-arg GIT_REPO_URL=$(GIT_REPO_URL) \
			--build-arg GIT_BRANCH=$(GIT_BRANCH) \
			--build-arg GIT_REPO_PATH=$(GIT_REPO_PATH) \
			--build-arg AUTO_UPDATE=$(AUTO_UPDATE) \
			--build-arg UPDATE_INTERVAL=$(UPDATE_INTERVAL) \
			-t $(IMAGE_NAME):$(TAG)-$$platform_tag \
			--load \
			.; \
	done

# 构建并推送镜像
all: build push

# 清理构建缓存
clean:
	docker buildx rm multiarch-builder || true
