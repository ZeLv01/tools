#!/bin/bash
#
set -e
#set -x

RED='\033[0;31m'
GREEN='\033[1;32m'
NC='\033[0m'

install_nginxd_dir="/usr/local/nginxd"
service_config_dir="/etc/systemd/system"

nginx_service_name="nginxd"
csudo=""
if command -v sudo >/dev/null; then
  csudo="sudo "
fi

function clean_service_on_systemd() {
    ${csudo}systemctl daemon-reload
    nginx_service_config="${service_config_dir}/${nginx_service_name}.service"
    if [ -d ${install_nginxd_dir} ]; then
      if systemctl is-active --quiet ${nginx_service_name}; then
        echo "Nginx is running, stopping it..."
        ${csudo}systemctl stop ${nginx_service_name} &>/dev/null || echo &>/dev/null
      fi
      ${csudo}systemctl disable ${nginx_service_name} &>/dev/null || echo &>/dev/null
      ${csudo}rm -f ${nginx_service_config}
    fi
}

clean_service_on_systemd

${csudo}rm -rf /usr/bin/rmnginx ||:
${csudo}rm -rf ${install_nginxd_dir}

echo -e "${GREEN}Nginx is removed successfully!${NC}"
echo
