#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/asylumexp/Proxmox/raw/main/LICENSE
# Source: https://technitium.com/dns/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing ASP.NET Core Runtime"
curl -SL -o dotnet.tar.gz https://builds.dotnet.microsoft.com/dotnet/Sdk/9.0.306/dotnet-sdk-9.0.306-linux-arm64.tar.gz
curl -SL -o aspnet.tar.gz https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/9.0.10/aspnetcore-runtime-9.0.10-linux-arm64.tar.gz
$STD mkdir -p /usr/share/dotnet
$STD tar -zxf dotnet.tar.gz -C /usr/share/dotnet
$STD tar -zxf aspnet.tar.gz -C /usr/share/dotnet
ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
msg_ok "Installed ASP.NET Core Runtime"

RELEASE=$(curl -fsSL https://technitium.com/dns/ | grep -oP 'Version \K[\d.]+')
fetch_and_deploy_from_url "https://download.technitium.com/dns/DnsServerPortable.tar.gz" /opt/technitium/dns
echo "${RELEASE}" >~/.technitium

msg_info "Creating service"
mkdir -p /etc/dns /var/log/technitium/dns
sed -i '/^User=/d;/^Group=/d' /opt/technitium/dns/systemd.service
cp /opt/technitium/dns/systemd.service /etc/systemd/system/technitium.service
systemctl enable -q --now technitium
msg_ok "Service created"

motd_ssh
customize
cleanup_lxc
