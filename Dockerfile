# 使用 Python 3.9 作为基础镜像
FROM python:3.12.9-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    AUTO_UPDATE=true \
    FLASK_RUN_HOST=0.0.0.0

# 配置pip使用阿里云镜像源
RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY requirements.txt .
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

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
# 确保目录存在\n\
mkdir -p "$GIT_REPO_PATH"\n\
\n\
# 初始化或更新 Git 仓库\n\
if [ ! -d "$GIT_REPO_PATH/.git" ]; then\n\
    echo "Initializing Git repository at $GIT_REPO_PATH..."\n\
    cd "$GIT_REPO_PATH"\n\
    git init\n\
    git remote add origin "$GIT_REPO_URL"\n\
    git fetch origin\n\
    git checkout -b "${GIT_BRANCH:-main}" --track "origin/${GIT_BRANCH:-main}"\n\
else\n\
    echo "Git repository found at $GIT_REPO_PATH"\n\
    cd "$GIT_REPO_PATH"\n\
    git fetch origin\n\
    git reset --hard "origin/${GIT_BRANCH:-main}"\n\
fi\n\
\n\
# 启动后台更新检查\n\
if [ "$AUTO_UPDATE" = "true" ]; then\n\
    echo "Starting background update checker..."\n\
    while true; do\n\
        cd "$GIT_REPO_PATH"\n\
        if git pull origin "${GIT_BRANCH:-main}"; then\n\
            echo "Update check completed successfully"\n\
        else\n\
            echo "Warning: Update check failed, will retry later"\n\
        fi\n\
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
