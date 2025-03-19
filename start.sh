#!/bin/bash
# 首次启动时检查更新
echo "Performing initial update check..."
cd $GIT_REPO_PATH
git pull

# 启动后台更新检查
if [ "$AUTO_UPDATE" = "true" ]; then
    echo "Starting background update checker..."
    cd $GIT_REPO_PATH
    git pull
    echo "Update check completed. Waiting for $UPDATE_INTERVAL seconds..."
fi

# 启动主应用
echo "Starting the application..."
exec python app.py