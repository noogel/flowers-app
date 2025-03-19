# 使用 Python 3.9 作为基础镜像
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV GIT_REPO_PATH=/app/flowers-app \
    AUTO_UPDATE=true \
    PYTHONUNBUFFERED=1

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    git \
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
# 首次启动时检查更新\n\
echo "Performing initial update check..."\n\
cd $GIT_REPO_PATH\n\
git pull\n\
\n\
# 启动后台更新检查\n\
if [ "$AUTO_UPDATE" = "true" ]; then\n\
    echo "Starting background update checker..."\n\
    cd $GIT_REPO_PATH\n\
    git pull\n\
fi\n\
\n\
# 启动主应用\n\
echo "Starting the application..."\n\
exec python app.py' > /app/start.sh && chmod +x /app/start.sh

# 暴露端口
EXPOSE 5000

# 启动命令
CMD ["/app/start.sh"]
