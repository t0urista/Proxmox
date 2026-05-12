#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/asylumexp/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/asylumexp/Proxmox/raw/main/LICENSE
# Source: https://rxresume.org

APP="Reactive-Resume"
var_tags="${var_tags:-documents}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/reactive-resume.service ]]; then
    msg_error "No $APP Installation Found!"
    exit
  fi
  if check_for_gh_release "reactive-resume" "amruthpillai/reactive-resume"; then
    msg_info "Stopping services"
    systemctl stop reactive-resume
    msg_ok "Stopped services"

    ensure_dependencies git

    cp /opt/reactive-resume/.env /opt/reactive-resume.env.bak
    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "reactive-resume" "amruthpillai/reactive-resume" "tarball" "latest" "/opt/reactive-resume"

    msg_info "Updating Reactive Resume (Patience)"
    cd /opt/reactive-resume
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    corepack enable
    corepack prepare --activate
    export CI="true"
    export NODE_ENV="production"
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    $STD pnpm run prisma:generate
    mv /opt/rxresume.env /opt/Reactive-Resume/.env
    msg_ok "Updated Reactive-Resume"

    msg_info "Updating Minio"
    systemctl stop minio
    cd /tmp
    curl -fsSL https://dl.min.io/server/minio/release/linux-arm64/minio.deb -o minio.deb
    $STD dpkg -i minio.deb
    rm -f /tmp/minio.deb
    msg_ok "Updated Minio"

    msg_info "Updating Browserless (Patience)"
    systemctl stop browserless
    cp /opt/browserless/.env /opt/browserless.env
    rm -rf /opt/browserless
    brwsr_tmp=$(mktemp)
    TAG=$(curl -fsSL https://api.github.com/repos/browserless/browserless/tags?per_page=1 | grep "name" | awk '{print substr($2, 3, length($2)-4) }')
    curl -fsSL https://github.com/browserless/browserless/archive/refs/tags/v"$TAG".zip -o "$brwsr_tmp"
    $STD unzip "$brwsr_tmp"
    mv browserless-"$TAG"/ /opt/browserless
    cd /opt/browserless
    $STD npm install typescript
    $STD npm install esbuild
    $STD npm install
    rm -rf src/routes/{chrome,edge,firefox,webkit}
    $STD node_modules/playwright-core/cli.js install --with-deps chromium
    $STD npm run build
    $STD npm run build:function
    $STD npm prune production
    mv /opt/browserless.env /opt/browserless/.env
    rm -f "$brwsr_tmp"
    msg_ok "Updated Browserless"

    msg_info "Restarting services"
    systemctl start chromium-printer reactive-resume
    msg_ok "Restarted services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
