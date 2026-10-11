#!/bin/bash
# ============================================
# NAS音乐交互式安装向导
# ============================================

echo "=========================================="
echo "    NAS音乐安装向导"
echo "=========================================="
echo ""

# 默认值
PORT=5200
PASSWORD=admin123
DATA_DIR=/opt/nas-music
MUSIC_DIR=/opt/nas-music/music
LX_VERSION=v2.0.2
GITHUB_RAW="https://raw.githubusercontent.com/dwtxaqgb1/nas-music/main"

# 1. 端口
read -p "请输入Web端口 [默认 $PORT]: " input
PORT=${input:-$PORT}

# 2. 密码
read -p "请输入管理密码 [默认 $PASSWORD]: " input
PASSWORD=${input:-$PASSWORD}

# 3. 数据目录
read -p "请输入数据目录 [默认 $DATA_DIR]: " input
DATA_DIR=${input:-$DATA_DIR}

# 4. 音乐目录
read -p "请输入音乐下载目录 [默认 $MUSIC_DIR]: " input
MUSIC_DIR=${input:-$MUSIC_DIR}

# 5. 后端版本
echo ""
echo "请选择落雪后端版本:"
echo "  1) v2.0.2 (稳定版, 推荐)"
echo "  2) v2.1.0"
echo "  3) v2.1.1"
echo "  4) v2.1.2"
echo "  5) latest (最新版)"
read -p "请输入选项 [默认 1]: " ver_sel
case ${ver_sel:-1} in
    2) LX_VERSION=v2.1.0 ;;
    3) LX_VERSION=v2.1.1 ;;
    4) LX_VERSION=v2.1.2 ;;
    5) LX_VERSION=latest ;;
    *) LX_VERSION=v2.0.2 ;;
esac

# 6. 加速地址
echo ""
echo "加速地址（留空默认直连GitHub）"
echo "如国内访问慢，输入加速地址前缀，例如：https://ghproxy.net/"
read -p "加速地址: " mirror_prefix
GITHUB_RAW="${mirror_prefix}https://raw.githubusercontent.com/dwtxaqgb1/nas-music/main"
echo "实际下载地址: $GITHUB_RAW"

# 确认
echo ""
echo "=========================================="
echo "    安装配置确认"
echo "=========================================="
echo "端口:       $PORT"
echo "密码:       $PASSWORD"
echo "数据目录:   $DATA_DIR"
echo "音乐目录:   $MUSIC_DIR"
echo "后端版本:   $LX_VERSION"
echo "下载源:     $GITHUB_RAW"
echo "=========================================="
read -p "确认安装? [Y/n]: " confirm
if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
    echo "已取消"
    exit 0
fi

# 安装方式
echo ""
echo "请选择安装方式:"
echo "  1) 全新安装（保留旧数据）"
echo "  2) 卸载后全新安装（清空所有数据）"
read -p "请输入选项 [默认 1]: " install_mode
if [ "$install_mode" = "2" ]; then
    echo "卸载旧版本..."
    docker-compose -f $DATA_DIR/docker-compose.yml down 2>/dev/null
    docker stop nas-music nas-music-lx 2>/dev/null
    docker rm nas-music nas-music-lx 2>/dev/null
    rm -rf $DATA_DIR/data
fi

# 检查Docker
echo ""
if ! command -v docker &> /dev/null; then
    echo "错误：未检测到Docker，请先安装Docker"
    exit 1
fi

# 检查docker-compose
if ! command -v docker-compose &> /dev/null; then
    COMPOSE="docker compose"
else
    COMPOSE="docker-compose"
fi

# 创建目录
echo "创建目录..."
mkdir -p $DATA_DIR/data
mkdir -p $MUSIC_DIR
mkdir -p $DATA_DIR/web

# 下载前端文件
echo "下载前端文件..."
curl -sSL "$GITHUB_RAW/app/web/index.html" -o $DATA_DIR/web/index.html
curl -sSL "$GITHUB_RAW/app/web/app.js" -o $DATA_DIR/web/app.js
curl -sSL "$GITHUB_RAW/app/web/style.css" -o $DATA_DIR/web/style.css
curl -sSL "$GITHUB_RAW/app/lx_bridge.py" -o $DATA_DIR/lx_bridge.py

if [ ! -s $DATA_DIR/web/index.html ] || [ ! -s $DATA_DIR/web/app.js ]; then
    echo "错误：前端文件下载失败，请检查加速地址"
    exit 1
fi
echo "前端文件下载成功"

# 检查前端文件是否下载成功
if [ ! -s $DATA_DIR/web/index.html ] || [ ! -s $DATA_DIR/web/app.js ]; then
    echo "错误：前端文件下载失败，请检查网络或加速地址"
    exit 1
fi
echo "前端文件下载成功"


# 创建目录
mkdir -p $DATA_DIR/data
mkdir -p $DATA_DIR/music
mkdir -p $DATA_DIR/cache
mkdir -p $DATA_DIR/web
mkdir -p $DATA_DIR/nginx
mkdir -p $DATA_DIR/sidecar

# 下载文件
echo "下载文件..."
curl -sSL "$GITHUB_RAW/app/web/index.html" -o $DATA_DIR/web/index.html
curl -sSL "$GITHUB_RAW/app/web/app.js" -o $DATA_DIR/web/app.js
curl -sSL "$GITHUB_RAW/app/web/style.css" -o $DATA_DIR/web/style.css
curl -sSL "$GITHUB_RAW/app/lx_bridge.py" -o $DATA_DIR/lx_bridge.py
curl -sSL "$GITHUB_RAW/app/sidecar/server.js" -o $DATA_DIR/sidecar/server.js

# nginx配置（复用fpk）
cat > $DATA_DIR/nginx/default.conf <<'NGINXEOF'
server {
    listen 80;
    server_name _;

    location = / {
        proxy_pass http://lxserver:9527/index.html;
    }

    location = /api/admin/password {
        proxy_pass http://sidecar:3001;
        proxy_set_header Content-Type application/json;
    }

    location /api/v1/ {
        proxy_pass http://host.docker.internal:8773/api/v1/;
        proxy_set_header Host $host;
    }

    location /stream/ {
        proxy_pass http://host.docker.internal:8773/stream/;
        proxy_buffering off;
    }

    location /cover/ {
        proxy_pass http://host.docker.internal:8773/cover/;
    }

    location ~ ^/(list-saved|search-sources|fetch-source|save-source|delete-saved|export-source|download-saved|set-token|get-token|set_playmode|get_playmode|get-mirror|set-mirror|extract-zip) {
        proxy_pass http://host.docker.internal:8773;
    }

    location / {
        proxy_pass http://lxserver:9527;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINXEOF

# docker-compose（3容器）
cat > $DATA_DIR/docker-compose.yml <<EOF
services:
  lxserver:
    image: xcq0607/lxserver:$LX_VERSION
    container_name: nas-music-lx
    restart: unless-stopped
    expose:
      - "9527"
    environment:
      - NODE_ENV=production
      - FRONTEND_PASSWORD=$PASSWORD
      - PORT=9527
      - BIND_IP=0.0.0.0
      - DATA_PATH=/server/data
      - LOG_PATH=/server/data/logs
    volumes:
      - $DATA_DIR/data:/server/data
      - $DATA_DIR/music:/server/music
      - $DATA_DIR/cache:/server/cache
      - $DATA_DIR/web:/server/public
    networks:
      - nas-music-net

  sidecar:
    image: node:20-alpine
    container_name: nas-music-sidecar
    restart: unless-stopped
    expose:
      - "3001"
    volumes:
      - $DATA_DIR/sidecar/server.js:/app/server.js:ro
      - $DATA_DIR/data:/data
    networks:
      - nas-music-net
    command: node /app/server.js

  nginx:
    image: nginx:alpine
    container_name: nas-music
    restart: unless-stopped
    ports:
      - "$PORT:80"
    volumes:
      - $DATA_DIR/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - lxserver
      - sidecar
    networks:
      - nas-music-net
    extra_hosts:
      - "host.docker.internal:host-gateway"

networks:
  nas-music-net:
EOF

# 启动bridge
echo "启动bridge..."
pkill -f lx_bridge.py 2>/dev/null
SOURCE_DIR=$DATA_DIR/data/users/source/_open nohup python3 $DATA_DIR/lx_bridge.py 8773 > $DATA_DIR/bridge.log 2>&1 &

# 启动容器
echo "启动容器..."
cd $DATA_DIR
$COMPOSE up -d

sleep 5
echo ""
echo "=== 安装成功 ==="
echo "访问地址: http://本机IP:$PORT"
echo "管理密码: $PASSWORD"
