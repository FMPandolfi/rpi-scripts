#! /bin/sh
# Configure language
echo "Enter the main language code (leave blank for 'it')"
read LANG
[ -z "$LANG" ] && LANG="it"
cp /etc/default/keyboard /etc/default/keyboard.bak && sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'$LANG'\"/g' /etc/default/keyboard

# Configure timezone
echo "Enter timezone (leave blank for Europe/Rome)"
read TIMEZONE
[ -z "$TIMEZONE" ] && TIMEZONE="Europe/Rome"
timedatectl set-timezone $TIMEZONE

# Create a new user and replace "ubuntu"
echo "Enter the main username (leave blank to leave it 'ubuntu')"
read NEWUSER 
[ -z "$NEWUSER" ] || adduser $NEWUSER && usermod -aG sudo,admin $NEWUSER && userdel -rf 'ubuntu'

# Update and upgrade
echo "Updating and upgrading"
apt update -y
apt upgrade -y

# Setup the firewall
echo "Setting up the firewall"
FWSERVICES=('OpenSSH')
for i in "${FWSERVICES[@]}"; do
    ufw allow $i
done
ufw enable

# Setup the networking
echo "Setting up the networking"
echo "Removing 'cloud-init'"
cp /etc/cloud/cloud.cfg.d/90_dpkg.cfg /etc/cloud/cloud.cfg.d/90_dpkg.cfg.bak && echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg && apt purge cloud-init - y && rm -rf /etc/cloud/ & rm -rf /var/lib/cloud/

echo "Installing required packages"
NETPACKAGES=('net-tools' 'network-manager' 'network-manager-openvpn' 'netfilter-persistent' 'iptables-persistent')
apt install ${NETPACKAGES[@]}

echo "Configuring NetworkManager"
cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.bak && sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
systemctl start NetworkManager.service
systemctl enable NetworkManager.service

#Finish
echo "Rebooting"
reboot