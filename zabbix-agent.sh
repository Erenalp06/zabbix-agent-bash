#!/bin/bash


ZABBIX_SERVER_IP="192.168.122.6"


if dpkg-query -W -f='${Status}' zabbix-agent 2>/dev/null | grep -q "ok installed"; then
    echo "zabbix-agent kurulu. Kaldırılıyor..."
    apt-get remove --purge -y zabbix-agent
    echo "Mevcut zabbix-agent kaldırıldı. Yeniden kuruluyor..."
fi


UBUNTU_CODENAME=$(lsb_release -sc)

convert_codename_to_zabbix_format(){
    case $1 in
        "bionic")
            echo "ubuntu18.04"
            ;;
        "focal")
            echo "ubuntu20.04"
            ;;
        "jammy")
            echo "ubuntu22.04"
            ;;
        *)
            echo "Unsupported Ubuntu version: $1" >&2
            exit 1
            ;;
    esac
}


UBUNTU_VERSION=$(convert_codename_to_zabbix_format $UBUNTU_CODENAME)


wget --no-check-certificate https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+${UBUNTU_VERSION}_all.deb
dpkg -i zabbix-release_latest+${UBUNTU_VERSION}_all.deb
apt-get update
apt-get install -y zabbix-agent


systemctl status zabbix-agent.service | tee -a zabbix_installation.log
journalctl -xe | tee -a zabbix_installation.log


sed -i "s/Server=127.0.0.1/Server=${ZABBIX_SERVER_IP}/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=${ZABBIX_SERVER_IP}/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix server/Hostname=$(hostname)/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# HostMetadata=/HostMetadata=linux_server/" /etc/zabbix/zabbix_agentd.conf


systemctl restart zabbix-agent
systemctl enable zabbix-agent

echo "Zabbix Agent kurulumu tamamlandı."
