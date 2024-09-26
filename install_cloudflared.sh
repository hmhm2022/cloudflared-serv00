#!/bin/sh

# 设置变量
HOME_DIR="${HOME}/cloudflared-serv00"
LOG_FILE="${HOME_DIR}/cloudflared.log"
MAX_LOG_SIZE=$((10 * 1024 * 1024))  # 10MB

# 检查Go编译器
check_go() {
    if ! command -v go >/dev/null 2>&1; then
        echo "错误: 未安装Go编译器。请先安装Go。"
        exit 1
    fi
}

# 下载并安装 cloudflared
install_cloudflared() {
    echo "开始安装 cloudflared..."
    GITHUB_URI="https://github.com/cloudflare/cloudflared"
    PAGE_CONTENT=$(fetch -q -o - ${GITHUB_URI}/releases)
    VERSION=$(echo "${PAGE_CONTENT}" | grep -o "href=\"/cloudflare/cloudflared/releases/tag/[^\"]*" | head -n 1 | sed "s;href=\"/cloudflare/cloudflared/releases/tag/;;")
    
    fetch -o cloudflared.tar.gz "${GITHUB_URI}/archive/refs/tags/${VERSION}.tar.gz" || { echo "下载失败"; exit 1; }
    tar zxf cloudflared.tar.gz || { echo "解压失败"; exit 1; }
    cd cloudflared-${VERSION#v} || { echo "进入目录失败"; exit 1; }
    
    go build -o cloudflared ./cmd/cloudflared || { echo "编译失败"; exit 1; }
    mv -f ./cloudflared ${HOME_DIR}/cloudflared-freebsd || { echo "移动文件失败"; exit 1; }
    chmod +x ${HOME_DIR}/cloudflared-freebsd || { echo "修改权限失败"; exit 1; }
    cd ${HOME_DIR}
    rm -rf cloudflared.tar.gz cloudflared-${VERSION#v}
    echo "cloudflared 安装完成。"
}

# 获取并验证用户输入的 token
get_and_verify_token() {
    while true; do
        printf "请输入您的 Cloudflare 隧道 token: "
        read -r ARGO_AUTH
        if [ -z "$ARGO_AUTH" ]; then
            echo "未输入 token，跳过配置步骤。"
            return 1
        fi
        
        echo "正在验证 token..."
        ${HOME_DIR}/cloudflared-freebsd tunnel --edge-ip-version auto --protocol http2 --no-autoupdate run --token $ARGO_AUTH > /dev/null 2>&1 &
        CLOUDFLARED_PID=$!
        sleep 5
        
        if kill -0 $CLOUDFLARED_PID 2>/dev/null; then
            echo "Token 验证成功！"
            kill $CLOUDFLARED_PID
            wait $CLOUDFLARED_PID 2>/dev/null
            return 0
        else
            echo "Token 验证失败。请检查您的 token 并重新输入。"
        fi
    done
}

# 创建启动脚本
create_start_script() {
    cat <<EOF > ${HOME_DIR}/start_cloudflared.sh
#!/bin/sh
pkill -f cloudflared-freebsd 2>/dev/null
rotate_log() {
    if [ -f "$LOG_FILE" ] && [ \$(stat -f %z "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
    fi
}
rotate_log
TZ='Asia/Shanghai' nohup ${HOME_DIR}/cloudflared-freebsd tunnel --edge-ip-version auto --protocol http2 --no-autoupdate run --token $ARGO_AUTH >> ${LOG_FILE} 2>&1 &
EOF
    chmod +x ${HOME_DIR}/start_cloudflared.sh || { echo "创建启动脚本失败"; exit 1; }
    echo "启动脚本start_cloudflared.sh已创建。"
}

# 添加到用户的 crontab
add_to_crontab() {
    (crontab -l 2>/dev/null | grep -v "@reboot cd ${HOME_DIR} && bash start_cloudflared.sh"; echo "@reboot cd ${HOME_DIR} && bash start_cloudflared.sh") | crontab - || { echo "添加到crontab失败"; exit 1; }
    echo "已添加到 crontab，start_cloudflared.sh将在系统重启后自动运行。"
}

# 卸载功能
uninstall() {
    echo "正在卸载 cloudflared..."
    pkill -f cloudflared-freebsd
    rm -f ${HOME_DIR}/cloudflared-freebsd ${HOME_DIR}/start_cloudflared.sh ${LOG_FILE}
    crontab -l 2>/dev/null | grep -v "@reboot cd ${HOME_DIR} && bash start_cloudflared.sh" | crontab -
    echo "cloudflared 已卸载。"
}

# 主函数
main() {
    if [ "$1" = "uninstall" ]; then
        uninstall
        exit 0
    fi

    check_go
    mkdir -p ${HOME_DIR} || { echo "创建目录失败"; exit 1; }
    cd ${HOME_DIR} || { echo "进入目录失败"; exit 1; }
    install_cloudflared
    
    echo "cloudflared 已安装。您想现在配置并运行隧道吗？ (y/n)"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        if get_and_verify_token; then
            create_start_script
            add_to_crontab
            ${HOME_DIR}/start_cloudflared.sh
            echo "Cloudflared 已配置并启动。它将在系统重启后自动运行。"
        else
            echo "未配置 token。您可以稍后手动配置和运行 cloudflared。"
        fi
    else
        echo "跳过配置。您可以稍后手动配置和运行 cloudflared。"
    fi
}

# 运行主函数
main "$@"
