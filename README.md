# NAS歌曲下载

基于落雪音乐的NAS音乐下载系统，支持搜索、播放、下载音源。

## 功能

- 音乐搜索、在线播放、下载
- 音源仓库管理，支持导入/导出/删除音源
- 播放模式切换（边下边播/下完再播）
- 密码保护
- 支持自定义音源JS

## 一键安装（推荐）

```bash
bash <(curl -sSL https://ghproxy.net/https://raw.githubusercontent.com/dwtxaqgb1/nas-music/main/install.sh)
```

交互式安装向导，会询问：
- Web端口（默认5200）
- 管理密码（默认admin123）
- 数据目录
- 音乐下载目录
- 落雪后端版本（v2.0.2稳定版 / latest最新版）
- GitHub加速地址（国内访问慢可填，留空直连）
- 安装方式（全新安装/卸载后安装）

## 系统要求

- Linux系统（X86/ARM均可）
- 已安装Docker和Docker Compose

## 访问

安装完成后访问 `http://NAS_IP:5200`，默认密码 `admin123`。

## 常用命令

```bash
# 查看日志
cd /opt/nas-music && docker compose logs -f

# 重启
cd /opt/nas-music && docker compose restart

# 停止
cd /opt/nas-music && docker compose down

# 卸载
docker stop nas-music nas-music-lx nas-music-sidecar
docker rm nas-music nas-music-lx nas-music-sidecar
rm -rf /opt/nas-music
pkill -f lx_bridge.py
```
