✨ **cloudflared-serv00:** a script to install Cloudflare Tunnel on Serv00

**Function:**
- Installs and uninstalls Cloudflare Tunnel and manages Cron jobs on the Serv00.

**Usage:**
1. Login to Cloudflare Zero Trust --> Networks --> Tunnels --> Create a tunnel --> Cloudflared

2. Run the script on your VPS:
```🐚
curl -O https://raw.githubusercontent.com/X-49/cloudflared-serv00/dev/install_cloudflared.sh && chmod +x install_cloudflared.sh && ./install_cloudflared.sh
```
3. According to the prompts, enter the Cloudflared tunnel token you received. Settings to start the tunnel and Cron jobs will be added automatically.

4. Execute the following command to delete the tunnel and Cron job:
```🐚
bash install_cloudflared.sh uninstall
```
