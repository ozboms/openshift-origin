#!/bin/bash
echo $(date) " - Starting Bastion Prep Script"

PRIVATEKEY=$4
SUDOUSER=$5

# Generate private keys for use by Ansible
echo $(date) " - Generating Private keys for use by Ansible for OpenShift Installation"

runuser -l $SUDOUSER -c "echo \"$PRIVATEKEY\" > ~/.ssh/id_rsa"
runuser -l $SUDOUSER -c "chmod 600 ~/.ssh/id_rsa*"

# Install EPEL repository
echo $(date) " - Installing EPEL"

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

echo $(date) " - EPEL successfully installed"

# Update system to latest packages
echo $(date) " - Update system to latest packages"
yum -y update --exclude=WALinuxAgent
echo $(date) " - System update complete"

# Install base packages and update system to latest packages
echo $(date) " - Install base packages"
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion httpd-tools kexec-tools sos psacct
#yum -y update glusterfs-fuse
systemctl restart dbus
echo $(date) " - Base package installation complete"

# Install Ansible and pyOpenSSL
# python-passlib needed for metrics

echo $(date) " - Installing Ansible, pyOpenSSL and python-passlib"
yum -y --enablerepo=epel install pyOpenSSL python-passlib ansible
echo $(date) " - Ansible, pyOpenSSL and py-passlib installed successfully"

# Install java to support metrics
echo $(date) " - Installing Java"
yum -y install java-1.8.0-openjdk-headless
echo $(date) " - Java installed successfully"

# Installing Azure CLI
# From https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum
echo $(date) " - Installing Azure CLI"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install -y azure-cli
echo $(date) " - Azure CLI installation complete"

# Install ImageMagick to resize image for Custom Header
sudo yum install -y ImageMagick

# Configure DNS so it always has the domain name
echo $(date) " - Adding DOMAIN to search for resolv.conf"
echo "DOMAIN=`domainname -d`" >> /etc/sysconfig/network-scripts/ifcfg-eth0

# Run Ansible Playbook to update ansible.cfg file
echo $(date) " - Updating ansible.cfg file"
wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 5 https://raw.githubusercontent.com/microsoft/openshift-container-platform-playbooks/master/updateansiblecfg-origin.yaml
ansible-playbook -f 10 ./updateansiblecfg-origin.yaml

echo $(date) " - Script Complete"