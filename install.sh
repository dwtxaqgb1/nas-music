#!/bin/bash
# ============================================
# NAS音乐安装脚本
# ============================================


echo "=========================================="
echo "    NAS音乐安装"
echo "=========================================="
echo ""

# 1. 安装方式
echo "请选择安装方式:"
echo "  1) 全新安装（清空所有数据）"
echo "  2) 更新安装（保留数据）"
read -p "请输入选项 [默认 1]: " install_mode
install_mode=${install_mode:-1}

# 2. 端口
read -p "Web端口 [默认 5200]: " input
PORT=${input:-5200}

# 3. 密码
read -p "管理密码 [默认 admin123]: " input
PASSWORD=${input:-admin123}

# 4. 数据目录
read -p "数据目录 [默认 /opt/nas-music]: " input
DATA_DIR=${input:-/opt/nas-music}

# 5. 音乐目录
read -p "音乐下载目录 [默认 $DATA_DIR/music]: " input
MUSIC_DIR=${input:-$DATA_DIR/music}

# 6. 后端版本
echo ""
echo "落雪后端版本:"
echo "  1) v2.0.2 (稳定版)"
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
echo "GitHub加速地址"
read -p "加速地址 [默认 https://ghproxy.net/]: " mirror_prefix
mirror_prefix=${mirror_prefix:-https://ghproxy.net/}
GITHUB_RAW="${mirror_prefix}https://raw.githubusercontent.com/dwtxaqgb1/nas-music/main"
echo "下载源: $GITHUB_RAW"

MUSIC_DIR=$DATA_DIR/music

# 全新安装
if [ "$install_mode" = "1" ]; then
    echo "全新安装，清理旧版本..."
    docker stop nas-music nas-music-lx nas-music-sidecar 2>/dev/null
    docker rm nas-music nas-music-lx nas-music-sidecar 2>/dev/null
    pkill -f lx_bridge.py 2>/dev/null
    rm -rf $DATA_DIR
fi

# 更新安装
if [ "$install_mode" = "2" ]; then
    echo "更新安装，保留数据..."
    docker stop nas-music nas-music-lx nas-music-sidecar 2>/dev/null
    docker rm nas-music nas-music-lx nas-music-sidecar 2>/dev/null
    pkill -f lx_bridge.py 2>/dev/null
fi

echo ""
echo "端口: $PORT"
echo "密码: $PASSWORD"
echo "数据目录: $DATA_DIR"
echo "版本: $LX_VERSION"
echo ""

mkdir -p $DATA_DIR/data
mkdir -p $DATA_DIR/music
mkdir -p $DATA_DIR/cache
mkdir -p $DATA_DIR/web
mkdir -p $DATA_DIR/nginx
mkdir -p $DATA_DIR/sidecar

echo "下载文件..."
curl -sSL "$GITHUB_RAW/app/web/index.html" -o $DATA_DIR/web/index.html
curl -sSL "$GITHUB_RAW/app/web/app.js" -o $DATA_DIR/web/app.js
curl -sSL "$GITHUB_RAW/app/web/style.css" -o $DATA_DIR/web/style.css
curl -sSL "$GITHUB_RAW/app/lx_bridge.py" -o $DATA_DIR/lx_bridge.py
curl -sSL "$GITHUB_RAW/app/sidecar/server.js" -o $DATA_DIR/sidecar/server.js

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

echo "启动bridge..."
SOURCE_DIR=$DATA_DIR/data/users/source/_open nohup python3 $DATA_DIR/lx_bridge.py 8773 > $DATA_DIR/bridge.log 2>&1 &

echo "启动容器..."
cd $DATA_DIR
docker compose up -d

sleep 5
echo ""
echo "=== 安装成功 ==="
echo "访问地址: http://本机IP:$PORT"
echo "管理密码: $PASSWORD"
