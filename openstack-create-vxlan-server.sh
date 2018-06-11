#!/bin/bash
#-------------------------------
# create openstack Server
# by openbox2008
# 2018-06-08
#-------------------------------
#脚本在控制节点172.16.100.70执行

#1.创建openstack路由器
openstack router create router01 
 
#2.创建openstack内部网络
openstack network create int_net --provider-network-type vxlan 
 
#3.创建子网,IP池自已定义
openstack subnet create subnet01 --network int_net --subnet-range 10.18.100.0/24 --gateway 10.18.100.1 --dns-nameserver 114.114.114.114
 

#4.将内部网络添加到路由器上
openstack router add subnet router01 subnet01


#5.创建外部网络
openstack network create --provider-physical-network physnet1 --provider-network-type flat --external ext_net 

#6.创建外部网络子网
openstack subnet create subnet2 --network ext_net --subnet-range 10.16.100.0/24 --allocation-pool start=10.16.100.200,end=10.16.100.254 --gateway 10.16.100.1 --dns-nameserver 114.114.114.114 --no-dhcp 

 
#7.将网络添加到路由器上
openstack router set router01 --external-gateway ext_net 



#----以下手动执行：

#8.创建flavor
openstack flavor create  --vcpus 1 --ram 512 --disk 1 test

#9.查看网络
Int_Net_ID=`openstack network list | grep int_net | awk '{ print $2 }'` 
# openstack image list 
 
#10.创建keypair
ssh-keygen -q -N "" 
Enter file in which to save the key (/root/.ssh/id_rsa):

#添加公钥
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey 
 
#创建虚拟机
openstack server create --flavor m1.small --image cirros--security-group default --nic net-id=$Int_Net_ID --key-name mykey cirros
openstack server list 
 
#分配浮动IP
openstack floating ip create ext_net 
 
#分配浮动IP给虚拟机
openstack server add floating ip CentOS_7 172.16.100.201 

#确认配置
openstack floating ip show 10.16.100.201 
 
#查看虚拟机
openstack server list 
 
#配置安全组icmp
openstack security group rule create --protocol icmp --ingress default 
 
#配置安全组SSH
openstack security group rule create --protocol tcp --dst-port 22:22 default 
 
#查看安全组
openstack security group rule list 
 
#查看虚拟机
openstack server list 
 
#登录虚拟机
ssh centos@172.16.100.201 

