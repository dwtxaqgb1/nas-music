# NAS音乐搜索下载

基于落雪音乐(lxserver)的NAS音乐搜索、播放与下载工具，桥接飞牛音乐App。

## 功能

- 音乐搜索、在线播放
- 排行榜浏览
- 歌单收藏
- 批量下载到NAS
- 音源管理（上传/导入/导出/启用禁用）
- 边下边播 / 下完再播
- 飞牛音乐App桥接
- 管理密码保护
- 手机端自适应

## SSH手动安装

### 1. 安装Docker和Docker Compose

```bash
# 飞牛系统已自带Docker，跳过
```

### 2. 创建目录

```bash
sudo mkdir -p /vol1/@appdata/com.nasmusic.download/data
sudo mkdir -p /vol1/@appdata/com.nasmusic.download/music
```

### 3. 下载docker-compose.yml

```bash
sudo mkdir -p /vol1/@appcenter/com.nasmusic.download
cd /vol1/@appcenter/com.nasmusic.download
# 从Release下载docker-compose.yml和nginx.conf
```

### 4. 启动服务

```bash
cd /vol1/@appcenter/com.nasmusic.download
sudo docker-compose up -d
```

### 5. 访问

浏览器打开 `http://NAS_IP:5200`，默认密码见docker-compose.yml中的FRONTEND_PASSWORD。

## 目录结构

- `app/web/` - 前端文件
- `app/cmd/` - 安装脚本
- `app/nginx/` - nginx配置
- `app/sidecar/` - 辅助服务
