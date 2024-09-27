✨  cloudflared-serv00 一个用于在Serv00 上安装 Cloudflare Tunnel 的脚本

功能： 在serv00上 安装、卸载 Cloudflare Tunnel 并管理Cron job

使用：

1、登录Cloudflare， Zero Trust——> Networks ——> Tunnel,  点击 Create a tunnel 选择Cloudflared 获取token

2、运行脚本：

    curl -O https://raw.githubusercontent.com/hmhm2022/cloudflared-serv00/main/install_cloudflared.sh && chmod +x install_cloudflared.sh && ./install_cloudflared.sh
    

3、根据提示，输入token ，完成配置启动隧道，并添加Cron job。

4、执行以下指令删除隧道和Cron job。

    bash install_cloudflared.sh uninstall
