#!/bin/bash
#-------------------------------
# install mariadb ,rabbitmq,memcache
# by openbox2008
# 2018-06-06
#-------------------------------

#1.安装rabbitmq
#安装软件包：
yum -y install rabbitmq-server
#启动消息队列服务并将其配置为随系统启动：
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service

#添加 openstack 用户：
rabbitmqctl add_user openstack RABBIT_PASS

#给``openstack``用户配置写和读权限：
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#RabbitMQ web管理

rabbitmq-plugins enable rabbitmq_management
#创建管理员用户，因为缺省的guest/guest用户只能在本地登录，所以先用命令行创建一个admin/123456，并让他成为管理员。
rabbitmqctl add_user admin 123456
rabbitmqctl set_user_tags admin administrator


#2.安装Memcache
#安装软件包：
yum -y install memcached python-memcached
#配置vim /etc/sysconfig/memcached
cat >/etc/sysconfig/memcached <<eof
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS=""    #设置为空，让所有IP都可以访问
eof

#启动Memcached服务，并且配置它随机启动。在另一台主机上测试访问memcached :telnet 172.16.70.70 11211
systemctl enable memcached.service
systemctl start memcached.service


#3.安装mariadb
yum -y install mariadb mariadb-server python2-PyMySQL

#创建并编辑 /etc/my.cnf.d/openstack.cnf.
#编辑[mysqld] 部分，设置 `bind-address`值为控制节点的管理网络IP地址以使得其它节点可以通过管理网络访问数据库：
cat >/etc/my.cnf.d/openstack.cnf <<eof
[mysqld]
bind-address = 172.16.100.70
character-set-server = utf8
collation-server = utf8_general_ci
max_connections = 4096
innodb_file_per_table
default-storage-engine = innodb
eof

#启动数据库服务，并将其配置为开机自启：
systemctl enable mariadb.service
systemctl start mariadb.service

#这一步需要最后手动来操作，设置安全密码
#mysql_secure_installation   






