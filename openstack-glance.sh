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



#4.安装软件包
yum  -y install openstack-glance

#5.修改配置文件
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bak_$(date +%F_%T)
cat >/etc/glance/glance-api.conf<<eof
[DEFAULT]
bind_host = 0.0.0.0
notification_driver = noop

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@172.16.100.70/glance

[keystone_authtoken]
auth_uri = http://172.16.100.70:5000
auth_url = http://172.16.100.70:35357
memcached_servers = 172.16.100.70:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = 123456

[paste_deploy]
flavor = keystone
eof

#6.修改配置文件glance-registry.conf
cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.bak_$(date +%F%T)
cat >/etc/glance/glance-registry.conf <<EOF
[DEFAULT]
bind_host = 0.0.0.0
notification_driver = noop

[database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@172.16.100.70/glance

[keystone_authtoken]
auth_uri = http://172.16.100.70:5000
auth_url = http://172.16.100.70:35357
memcached_servers = 172.16.100.70:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = 123456

[paste_deploy]
flavor = keystone
EOF

#7.修改文件权限
chmod 640 /etc/glance/glance-api.conf /etc/glance/glance-registry.conf 
chown root:glance /etc/glance/glance-api.conf /etc/glance/glance-registry.conf

#8.创建数据库表结构
su -s /bin/bash glance -c "glance-manage db_sync" 

#9.启动服务并设置开机启动
systemctl start openstack-glance-api openstack-glance-registry 
systemctl enable openstack-glance-api openstack-glance-registry 




#10.下载镜像
wget -P ~/ http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img

#11.#加载镜像
openstack image create "cirros01"   --file ~/cirros-0.3.5-x86_64-disk.img   --disk-format qcow2 --container-format bare  --public


#其他镜像（根据个人需要）
wget -P ~/  http://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img 
openstack image create "Ubuntu1604" --file ~/ubuntu-16.04-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public 


















