#!/bin/bash
#####################################
#初始化linux环境
#2017-05-31 by openbox
#初始化脚本，后带主机名和IP参数
#例：linux-auto-init.sh network1 172.16.70.71
#####################################

#0.判断没带参数，不执行，输入提示信息
if [ "$1" == "" ] 
  then
   echo "please input hostname. example:linux-auto-init test 172.16.70.71"
  exit 1
fi

if [ "$2" == "" ] 
  then
   echo "please input IP address. example:linux-auto-init test 172.16.70.71 "
  exit 2
fi

#0.定义第二块网卡IP与第一块相同
init_name="$1"
init_ip="$2"

#1.修改主机名
hostnamectl set-hostname ${init_name}

#2.自动配置第二块网卡信息
sed -i 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-em2 
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/sysconfig/network-scripts/ifcfg-em2 
sed -i '/NETBOOT=yes/d' /etc/sysconfig/network-scripts/ifcfg-em2 

cat >/etc/sysconfig/network-scripts/ifcfg-em2 << END
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=em2
DEVICE=em2
ONBOOT=yes

IPADDR=${init_ip}
NETMASK=255.255.255.0
GATEWAY=172.16.70.10
DNS1=202.96.128.166
DNS2=8.8.8.8
END

#3.重启网络服务
systemctl restart network
if [ "$?" != "0" ]; then
	systemctl restart network
else
    site="www.qq.com"  
    ping -c1 -W1  ${site} &> /dev/null  
    if [ "$?" != "0" ]; then  
        echo "error:ping $site is timeout." 
		sleep 10
    fi         
fi


#4.更改/etc/hosts文件
cat >/etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.100.70 controller1 
172.16.100.71 network1
172.16.100.72 compute1
172.16.100.73 compute2
172.16.100.74 compute3

172.16.100.90 block
172.16.100.91 swift1
172.16.100.92 swift2
172.16.100.93 swift3
172.16.100.94 manila
EOF
	
#5.关闭防火墙
systemctl disable firewalld
systemctl stop firewalld
sed -i "s/\=enforcing/\=disabled/g" /etc/selinux/config
setenforce 0

#6.时间同步
#安装ntp
yum -y install ntp 

#修改配置文件/etc/ntp.conf
#cp -a /etc/ntp.conf  /etc/ntp.conf_bak

#控制节点如下修改
# vi /etc/ntp.conf
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
#server 127.127.1.0
#fudge 127.127.1.0 stratum 0

#其他节点如下修改,采用controller的时钟
cp -a /etc/ntp.conf  /etc/ntp.conf_bak
sed -i 's/server/#server/g' /etc/ntp.conf
sed -i '/^restrict ::1/a\server 172.16.100.70 prefer' /etc/ntp.conf

#启动服务并设置开机启动
systemctl enable ntpd 
systemctl restart ntpd 
#验证
ntpq -p

#7.安装阿里epel源
rpm -ivh https://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
#更新数据缓存
yum clean all && yum makecache
#升级所有包
yum -y upgrade
