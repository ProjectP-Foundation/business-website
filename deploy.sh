#!/bin/bash

# 配置变量
SERVER_USERNAME="ubuntu"
SERVER_HOST="110.40.152.53"
HUGO_LOCAL_PATH="./public"
HUGO_SERVER_PATH="/var/www/business.tranquiltina.com"

# 日志函数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 错误处理函数
handle_error() {
    log "错误发生在第 $1 行"
    exit 1
}

# 设置错误处理
trap 'exit_code=$?; if [ $exit_code -ne 0 ]; then handle_error $LINENO; fi' EXIT

# 测试 SSH 连接
log "测试 SSH 连接..."
ssh -o BatchMode=yes -o ConnectTimeout=5 $SERVER_USERNAME@$SERVER_HOST echo "SSH 连接成功" || {
    log "错误：无法连接到服务器。请检查你的 SSH 配置。"
    exit 1
}

# 构建 Hugo 网站
log "开始构建 Hugo 网站..."
hugo --minify

if [ ! -d "$HUGO_LOCAL_PATH" ]; then
    log "错误：Hugo 构建目录不存在"
    exit 1
fi

# 确保服务器上的目标目录存在
log "确保服务器上的目标目录存在..."
ssh $SERVER_USERNAME@$SERVER_HOST "sudo mkdir -p $HUGO_SERVER_PATH && sudo chown $SERVER_USERNAME:$SERVER_USERNAME $HUGO_SERVER_PATH"

# 部署 Hugo 网站
log "开始部署 Hugo 网站..."
rsync -avz --delete --stats --human-readable \
    -e "ssh -o StrictHostKeyChecking=no" \
    $HUGO_LOCAL_PATH/ $SERVER_USERNAME@$SERVER_HOST:$HUGO_SERVER_PATH

if [ $? -ne 0 ]; then
    log "Hugo 网站部署失败！"
    exit 1
fi
log "Hugo 网站部署成功！"

# 设置正确的权限
log "设置正确的权限..."
ssh $SERVER_USERNAME@$SERVER_HOST "sudo chown -R www-data:www-data $HUGO_SERVER_PATH"

# 检查 Nginx 配置并重新加载
log "检查 Nginx 配置并重新加载..."
ssh $SERVER_USERNAME@$SERVER_HOST "sudo nginx -t && sudo systemctl reload nginx"

if [ $? -eq 0 ]; then
    log "Nginx 配置检查并重新加载成功！"
else
    log "Nginx 配置检查或重新加载失败！"
    exit 1
fi

log "Hugo 网站部署完成！网站现在应该可以通过 business.tranquiltina.com 访问"
exit 0