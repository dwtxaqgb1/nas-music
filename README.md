# NAS音乐搜索下载

基于落雪音乐(lxserver)的NAS音乐搜索、播放与下载工具。

## 功能

- 音乐搜索、在线播放
- 排行榜浏览
- 歌单收藏
- 批量下载到NAS
- 音源管理（上传/导入/导出/启用禁用）
- 边下边播 / 下完再播
- 管理密码保护
- 手机端自适应

## 一键安装

适用于任何安装了Docker的Linux系统：

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dwtxaqgb1/nas-music/main/install.sh)
```

安装脚本会自动：
1. 创建目录
2. 下载镜像
3. 启动服务
4. 显示访问地址和密码

## 配置说明

安装前可修改脚本顶部的配置项：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| PORT | 5200 | Web访问端口 |
| PASSWORD | admin123 | 管理密码 |
| DATA_DIR | /opt/nas-music | 数据目录 |
| MUSIC_DIR | /opt/nas-music/music | 歌曲下载目录 |
| LX_VERSION | v2.0.2 | 落雪后端版本 |

## 常用命令

```bash
cd /opt/nas-music
docker-compose logs -f    # 查看日志
docker-compose restart    # 重启
docker-compose down       # 停止
docker-compose up -d      # 启动
```

## 飞牛fnOS安装

下载Release中的fpk文件，在飞牛应用中心安装即可。
