#!/bin/bash
# ============================================
# NAS音乐一键安装脚本
# 适用于任何安装了Docker的Linux系统
# ============================================

# ========== 配置项（按需修改） ==========

# Web访问端口（浏览器打开的端口）
PORT=5200

# 管理密码（登录后台用）
PASSWORD=admin123

# 数据目录（数据库、配置文件存放位置）
DATA_DIR=/opt/nas-music

# 歌曲下载目录（歌曲会下载到这里）
MUSIC_DIR=/opt/nas-music/music

# 落雪后端版本（可选：v2.0.2稳定版 / latest最新版）
LX_VERSION=v2.0.2

# ============================================
# 以下为安装逻辑，一般不需要修改
# ============================================

echo "=== NAS音乐一键安装 ==="
echo "端口: $PORT"
echo "密码: $PASSWORD"
echo "数据目录: $DATA_DIR"
echo "音乐目录: $MUSIC_DIR"
echo ""

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "错误：未检测到Docker，请先安装Docker"
    exit 1
fi

# 检查docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo "提示：未检测到docker-compose，使用docker compose"
    COMPOSE="docker compose"
else
    COMPOSE="docker-compose"
fi

# 创建目录
echo "创建目录..."
mkdir -p $DATA_DIR/data
mkdir -p $MUSIC_DIR

# 生成docker-compose.yml
echo "生成配置文件..."
cat > $DATA_DIR/docker-compose.yml <<EOF
services:
  lxserver:
    image: xcq0607/lxserver:$LX_VERSION
    container_name: nas-music
    restart: unless-stopped
    environment:
      - FRONTEND_PASSWORD=$PASSWORD
      - PORT=9527
    volumes:
      - $DATA_DIR/data:/server/data
      - $MUSIC_DIR:/server/cache
    ports:
      - "$PORT:9527"
EOF

# 拉取镜像并启动
echo "拉取镜像并启动服务..."
cd $DATA_DIR
$COMPOSE up -d

# 等待启动
echo "等待服务启动..."
sleep 5

# 检查状态
if $COMPOSE ps | grep -q "Up"; then
    echo ""
    echo "=== 安装成功 ==="
    echo "访问地址: http://本机IP:$PORT"
    echo "管理密码: $PASSWORD"
    echo ""
    echo "常用命令:"
    echo "  查看日志: cd $DATA_DIR && $COMPOSE logs -f"
    echo "  重启服务: cd $DATA_DIR && $COMPOSE restart"
    echo "  停止服务: cd $DATA_DIR && $COMPOSE down"
else
    echo "启动失败，请查看日志: cd $DATA_DIR && $COMPOSE logs"
fi
