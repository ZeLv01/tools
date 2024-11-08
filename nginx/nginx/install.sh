#!/bin/bash
#

set -e
#set -x

script_dir=$(dirname $(readlink -f "$0"))
service_config_dir="/etc/systemd/system"
nginx_port=6060
nginx_dir="/usr/local/nginxd"

# Color setting
RED='\033[0;31m'
GREEN='\033[1;32m'
GREEN_DARK='\033[0;32m'
GREEN_UNDERLINE='\033[4;32m'
NC='\033[0m'

csudo=""
if command -v sudo >/dev/null; then
  csudo="sudo "
fi

function clean_service_on_systemd() {
    ${csudo}systemctl daemon-reload
    nginx_service_config="${service_config_dir}/nginxd.service"
    if systemctl is-active --quiet nginxd; then
      echo "Nginx is running, stopping it..."
      ${csudo}systemctl stop nginxd &>/dev/null || echo &>/dev/null
    fi
    ${csudo}systemctl disable nginxd &>/dev/null || echo &>/dev/null
    ${csudo}rm -f ${nginx_service_config}
}

function install_service_on_systemd() {
    [ -f ${script_dir}/cfg/nginxd.service ] &&
      ${csudo}cp ${script_dir}/cfg/nginxd.service \
        ${service_config_dir}/ || :
    ${csudo}systemctl daemon-reload

    if ! ${csudo}systemctl enable nginxd &>/dev/null; then
      ${csudo}systemctl daemon-reexec
      ${csudo}systemctl enable nginxd
    fi
    ${csudo}systemctl start nginxd

}

function installProduct() {
    filenum=$(cat /etc/security/limits.conf |grep -v ^#|grep nofile|wc -l)
    nropennum=$(cat /etc/sysctl.conf |grep -v ^#|grep nr_open|wc -l)
    if [ $nropennum -lt 1 ];then
	    echo "The server openfile parameters are not adjusted, /etc/sysctl.conf have been adjusted. "
	    echo "fs.nr_open = 1048576" >>/etc/sysctl.conf
	    true || sysctl -p >/dev/null
    fi	    
    if [ $filenum -lt 1 ];then
        echo "The server openfile parameters are not adjusted, /etc/security/limits.conf have been adjusted. "
        echo "* soft nproc  65536" >>/etc/security/limits.conf
	echo "* soft nofile 65536" >>/etc/security/limits.conf
	echo "* soft stack  65536" >>/etc/security/limits.conf
	echo "* hard nproc  65536" >>/etc/security/limits.conf
	echo "* hard nofile 65536" >>/etc/security/limits.conf
	echo "* hard stack  65536" >>/etc/security/limits.conf
	echo "root soft nproc  65536" >>/etc/security/limits.conf
	echo "root soft nofile 65536" >>/etc/security/limits.conf
	echo "root soft stack  65536" >>/etc/security/limits.conf
	echo "root hard nproc  65536" >>/etc/security/limits.conf
	echo "root hard nofile 65536" >>/etc/security/limits.conf
        echo "root hard stack  65536" >>/etc/security/limits.conf
    fi
    taoskeeperonline=$(netstat -atnlp|grep 6043|grep LISTEN|wc -l)
    if [ "$taoskeeperonline" == 1 ];then
        echo -e "\033[44;31;5mPort 6043 in used! Please check or modify port ,then reinstall!\033[0m"
	exit 1
    fi
    taosexploreronline=$(netstat -atnlp|grep 6060|grep LISTEN|wc -l)
    if [ "$taosexploreronline" == 1 ];then
        echo -e "\033[44;31;5mPort 6060 in used! Please check or modify port ,then reinstall!\033[0m"
	exit 1
    fi
    taosadapterline=$(netstat -atnlp|grep 6041|grep LISTEN|wc -l)
    if [ "$taosadapterline" == 1 ];then
        echo -e "\033[44;31;5mPort 6041 in used! Please check or modify port ,then reinstall!\033[0m"
	exit 1
    fi

    ${csudo}mkdir -p ${nginx_dir}
    ${csudo}cp -r ${script_dir}/nginxd/* ${nginx_dir} && ${csudo}chmod 0555 ${nginx_dir}/*
    ${csudo}cp -r ${script_dir}/remove.sh ${nginx_dir} && ${csudo}chmod 777 ${nginx_dir}/remove.sh
    ${csudo}mkdir -p ${nginx_dir}/logs
    ${csudo}chmod 777 ${nginx_dir}/sbin/nginx

    ${csudo}rm -rf /usr/bin/rmnginx
    ${csudo}ln -s ${nginx_dir}/remove.sh /usr/bin/rmnginx


    clean_service_on_systemd
    install_service_on_systemd

    # Check if nginx is installed successfully
    #if type curl &>/dev/null; then
    #  if curl -sSf http://127.0.0.1:${nginx_port} &>/dev/null; then
    #    echo -e "\033[44;32;1mNginx is installed successfully!${NC}"
    #    openresty_work=true
    #  else
    #    echo -e "\033[44;31;5mNginx does not work! Please try again!\033[0m"
    #  fi
    #fi
    num=$(ps -ef|grep nginx|grep master|awk '{print $2}')
    if [ "$num" == "" ];then
	echo -e "\033[44;31;5mNginx does not work! Please check!\033[0m"
    else
	echo -e "\033[44;32;1mNginx is installed successfully!\033[0m"
    fi
    ${csudo}systemctl status nginxd
    echo -e  "\033[44;31;5mPlease modify the server IP address in the nginx configuration file!\033[0m"
}

## ==============================Main program starts from here============================
if pidof nginx &>/dev/null; then
  if pidof nginx &>/dev/null; then
      ${csudo}systemctl stop nginxd || :
      sleep 1
  fi
fi

installProduct

