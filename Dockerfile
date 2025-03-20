# 使用 Python 3.12 作为基础镜像
FROM python:3.12-slim-bullseye

# 设置工作目录
WORKDIR /app

# 设置构建参数
ARG GIT_REPO_URL
ARG GIT_BRANCH
ARG GIT_REPO_PATH
ARG AUTO_UPDATE
ARG UPDATE_INTERVAL

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    AUTO_UPDATE=${AUTO_UPDATE:-true} \
    FLASK_RUN_HOST=0.0.0.0 \
    GIT_REPO_URL=${GIT_REPO_URL} \
    GIT_BRANCH=${GIT_BRANCH:-main} \
    GIT_REPO_PATH=${GIT_REPO_PATH:-/app/flowers-app} \
    UPDATE_INTERVAL=${UPDATE_INTERVAL:-3600}

# 设置代理
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ENV HTTP_PROXY=$HTTP_PROXY
ENV HTTPS_PROXY=$HTTPS_PROXY
ENV NO_PROXY=$NO_PROXY

# 配置apt使用清华大学镜像源
RUN rm -f /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main" > /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main" >> /etc/apt/sources.list

# 配置pip使用清华大学镜像源
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY requirements.txt $GIT_REPO_PATH/
COPY app.py $GIT_REPO_PATH/
COPY templates/ $GIT_REPO_PATH/templates/
COPY static/ $GIT_REPO_PATH/static/

# 安装 Python 依赖
RUN pip install --no-cache-dir -r $GIT_REPO_PATH/requirements.txt

# 创建启动脚本
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# 检查必要的环境变量\n\
if [ -z "$GIT_REPO_PATH" ]; then\n\
    echo "Error: GIT_REPO_PATH environment variable is not set"\n\
    exit 1\n\
fi\n\
\n\
if [ -z "$GIT_REPO_URL" ]; then\n\
    echo "Error: GIT_REPO_URL environment variable is not set"\n\
    exit 1\n\
fi\n\
\n\
# 确保目标目录存在\n\
mkdir -p "$GIT_REPO_PATH"\n\
\n\
# 尝试更新代码\n\
update_code() {\n\
    # 创建临时目录\n\
    TEMP_DIR=$(mktemp -d)\n\
    echo "Created temporary directory: $TEMP_DIR"\n\
    \n\
    # 克隆仓库到临时目录\n\
    echo "Cloning Git repository to temporary directory..."\n\
    cd "$TEMP_DIR"\n\
    if git clone -b "${GIT_BRANCH:-main}" "$GIT_REPO_URL" .; then\n\
        # 复制必要文件到目标目录\n\
        echo "Copying necessary files to target directory..."\n\
        # 复制 Python 文件\n\
        cp -f app.py "$GIT_REPO_PATH/" 2>/dev/null || true\n\
        cp -f requirements.txt "$GIT_REPO_PATH/" 2>/dev/null || true\n\
        # 复制模板文件\n\
        if [ -d "templates" ]; then\n\
            cp -rf templates/* "$GIT_REPO_PATH/templates/" 2>/dev/null || true\n\
        fi\n\
        # 复制静态文件\n\
        if [ -d "static" ]; then\n\
            cp -rf static/* "$GIT_REPO_PATH/static/" 2>/dev/null || true\n\
        fi\n\
        echo "Code update successful"\n\
    else\n\
        echo "Warning: Failed to update code, using local files"\n\
    fi\n\
    \n\
    # 清理临时目录\n\
    cd /tmp\n\
    rm -rf "$TEMP_DIR"\n\
}\n\
\n\
# 首次更新代码\n\
update_code\n\
\n\
# 启动后台更新检查\n\
if [ "$AUTO_UPDATE" = "true" ]; then\n\
    echo "Starting background update checker..."\n\
    while true; do\n\
        update_code\n\
        sleep "${UPDATE_INTERVAL:-3600}"\n\
    done &\n\
fi\n\
\n\
# 启动主应用\n\
echo "Starting the application..."\n\
cd "$GIT_REPO_PATH"\n\
exec flask run --host=0.0.0.0' > /app/start.sh && chmod +x /app/start.sh

# 暴露端口
EXPOSE 5000

# 启动命令
CMD ["/app/start.sh"]
