#!/bin/bash

echo Install PXE server
yum -y install epel-release
yum -y install dhcp-server
yum -y install tftp-server
firewall-cmd --add-service=tftp
yum -y install nginx
firewall-cmd --add-service=nginx

# disable selinux or permissive
setenforce 0
# 
cat >/etc/dhcp/dhcpd.conf <<EOF
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;
subnet 10.0.0.0 netmask 255.255.255.0 {
	#option routers 10.0.0.254;
	range 10.0.0.100 10.0.0.120;
	class "pxeclients" {
	  match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
	  next-server 10.0.0.20;
	  if option architecture-type = 00:07 {
	    filename "uefi/shim.efi";
	    } else {
	    filename "pxelinux/pxelinux.0";
	  }
	}
}
EOF
systemctl start dhcpd

systemctl start tftp.service
yum -y install syslinux-tftpboot.noarch
mkdir /var/lib/tftpboot/pxelinux
cp /tftpboot/pxelinux.0 /var/lib/tftpboot/pxelinux
cp /tftpboot/libutil.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/menu.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/libmenu.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/ldlinux.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/vesamenu.c32 /var/lib/tftpboot/pxelinux

mkdir /var/lib/tftpboot/pxelinux/pxelinux.cfg

cat >/var/lib/tftpboot/pxelinux/pxelinux.cfg/default <<EOF
default menu
prompt 0
timeout 600
MENU TITLE Demo PXE setup
LABEL linux
  menu label ^Install system
  menu default
  kernel images/CentOS-8.4/vmlinuz
  append initrd=images/CentOS-8.4/initrd.img ip=enp0s3:dhcp inst.repo=http://10.0.0.20:8080
LABEL linux-auto
  menu label ^Auto install system
  kernel images/CentOS-8.4/vmlinuz
  append initrd=images/CentOS-8.4/initrd.img ip=enp0s3:dhcp inst.ks=http://10.0.0.20:8080/ks.cfg inst.repo=http://10.0.0.20:8080
LABEL local
  menu label Boot from ^local drive
  localboot 0xffff
EOF

mkdir -p /var/lib/tftpboot/pxelinux/images/CentOS-8.4/
curl -O http://ftp.mgts.by/pub/CentOS/8.4.2105/BaseOS/x86_64/os/images/pxeboot/initrd.img
curl -O http://ftp.mgts.by/pub/CentOS/8.4.2105/BaseOS/x86_64/os/images/pxeboot/vmlinuz
cp {vmlinuz,initrd.img} /var/lib/tftpboot/pxelinux/images/CentOS-8.4/


curl -O http://ftp.mgts.by/pub/CentOS/8.4.2105/BaseOS/x86_64/os/images/boot.iso
mkdir /mnt/centos8-install
mount -t iso9660 boot.iso /mnt/centos8-install


cp /vagrant/ks.cfg /usr/share/nginx/
cp -r /mnt/centos8-install/. /usr/share/nginx
cp /vagrant/default.conf /etc/nginx/conf.d/default.conf
systemctl restart nginx.service