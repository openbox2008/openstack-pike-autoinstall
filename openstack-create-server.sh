#!/bin/bash
#-------------------------------
# create openstack Server
# by openbox2008
# 2018-06-08
#-------------------------------
#脚本在控制节点172.16.100.70执行
 
 
#创建网络 获取project
projectID=`openstack project list | grep service | awk '{print $2}'`

#创建网络sharednet1
openstack network create --project $projectID --share --provider-network-type flat --provider-physical-network physnet1 sharednet1 
 
#创建子网
openstack subnet create subnet1 --network sharednet1 --project $projectID --subnet-range 10.16.100.0/24 --allocation-pool start=10.16.100.200,end=10.16.100.254 --gateway 10.16.100.1 --dns-nameserver 8.8.8.8  
 
#查看网络
openstack network list 
 
#创建虚拟机
netID=`openstack network list | grep sharednet1 | awk '{ print $2 }'` 
openstack image list 
 
#创建keypair
ssh-keygen -q -N "" 
#Enter file in which to save the key (/root/.ssh/id_rsa):
#添加公钥
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey 
 
#创建flavor
openstack flavor create  --vcpus 1 --ram 512 --disk 1 test01

#创建虚拟机
openstack server create --flavor test01  --image cirros --security-group default --nic net-id=$netID --key-name mykey TServer003
openstack server create --flavor  ubuntu  --image Ubuntu1604 --security-group  e173ec3d-f4b6-461f-99d9-4d1745353963 --nic net-id=ac42d61e-4856-4d2e-87d3-c3339a1945d4 --key-name mykey TServer005

#查看虚拟机
openstack server list 
 
#配置安全组
openstack security group rule create --protocol icmp --ingress default 
 
#允许ssh登录
openstack security group rule create --protocol tcp --dst-port 22:22 default 
 
#查看安全组
openstack security group rule list 
 
#登录虚拟机
ssh centos@10.16.100.XXX


