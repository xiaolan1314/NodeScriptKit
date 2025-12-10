#!/bin/bash
# NodeScriptKit 安装脚本（支持 GitHub 镜像）

# GitHub 镜像前缀（保持末尾带 /）
PROXY_URL="https://github.xloard.com/"

# 获取系统信息
goos=$(uname -s | tr '[:upper:]' '[:lower:]')
goarch=$(uname -m)

echo "Current OS: $goos"
echo "Current Architecture: $goarch"

if [ "$goos" == "darwin" ] || [ "$goos" == "linux" ] || [ "$goos" == "freebsd" ]; then
    ext=""
else
    echo "Unsupported OS: $goos"
    exit 1
fi

if [ "$goarch" == "x86_64" ]; then
    arch="amd64"
elif [ "$goarch" == "i386" ]; then
    arch="386"
elif [ "$goarch" == "arm64" ]; then
    arch="arm64"
else
    echo "Unsupported Architecture: $goarch"
    exit 1
fi

############################################
# 1. 下载 nskCore 最新版本
############################################
BIN_VERSION="$(curl -Ls -o /dev/null -w '%{url_effective}' ${PROXY_URL}https://github.com/NodeSeekDev/NskCore/releases/latest)"
BIN_VERSION="${BIN_VERSION##*/}"

BIN_FILENAME="nskCore-$goos-$arch$ext"
BIN_URL="${PROXY_URL}https://github.com/NodeSeekDev/NskCore/releases/download/$BIN_VERSION/$BIN_FILENAME"

echo "Downloading nskCore: $BIN_URL"
curl -Lso /usr/bin/nskCore "$BIN_URL"
chmod +x /usr/bin/nskCore

############################################
# 2. 处理 busybox tar（某些系统需要）
############################################
if tar --version 2>&1 | grep -qi 'busybox'; then
    if command -v apk >/dev/null 2>&1; then
        apk add --no-cache tar
    fi
fi

############################################
# 3. 下载 NodeScriptKit 菜单模块
############################################
MENU_URL="$(curl -Ls -o /dev/null -w '%{url_effective}' ${PROXY_URL}https://github.com/NodeSeekDev/NodeScriptKit/releases/latest)"
MENU_VERSION="${MENU_URL##*/}"

mkdir -p /etc/nsk/modules.d/default
mkdir -p /etc/nsk/modules.d/extend

cd /tmp
temp_dir=$(mktemp -d)

TAR_URL="${PROXY_URL}https://github.com/NodeSeekDev/NodeScriptKit/archive/refs/tags/$MENU_VERSION.tar.gz"

echo "Downloading menu: $TAR_URL"
curl -sL "$TAR_URL" | tar -xz -C "$temp_dir"

# 拷贝文件
[ -f "/etc/nsk/config.toml" ] || cp "$temp_dir"/*/menu.toml /etc/nsk/config.toml
rm -rf /etc/nsk/modules.d/default/*
cp "$temp_dir"/*/modules.d/* /etc/nsk/modules.d/default/

echo "$MENU_VERSION" > /etc/nsk/version

cp "$temp_dir"/*/nsk.sh /usr/bin/nsk
chmod +x /usr/bin/nsk

[ -f "/usr/bin/n" ] || ln -s /usr/bin/nsk /usr/bin/n

rm -rf "$temp_dir"

echo -e "\e[1;32mNSK 安装完成，可执行 n 或 nsk 打开菜单\e[0m"
