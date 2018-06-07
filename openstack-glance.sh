#!/bin/bash
#-------------------------------
# install openstack glance
# by openbox2008
# 2018-06-08
#-------------------------------

#1.在mariadb上为glance创建管理数据库并授权
mysql -h 172.16.100.70 -uroot -p123456 -e" CREATE DATABASE glance;flush privileges;\q;"

#进入数据库后，执行授权：
mysql -h 172.16.100.70 -uroot -p123456 -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%'  IDENTIFIED BY 'GLANCE_DBPASS';\q;"

#2.在keystone上创建glance服务
source ~/admin-openrc 
#(1）创建glance用户
openstack user create --domain default --password 123456 glance

#(2）添加用户角色，给glance用户添加admin权限
openstack role add --project service --user glance admin

#(3）创建名称为glance的镜像服务
openstack service create --name glance  --description "OpenStack Image" image

#3.创建镜像服务三个API端点public,internal,admin
#(1).public API端点
openstack endpoint create --region RegionOne  image public http://172.16.100.70:9292

#(2).internal API端点
openstack endpoint create --region RegionOne  image internal http://172.16.100.70:9292

#(3).admin API端点
openstack endpoint create --region RegionOne  image admin http://172.16.100.70:9292




















