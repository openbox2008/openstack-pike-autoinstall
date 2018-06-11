#!/bin/bash
#-------------------------------
# install openstack nova for controller
# by openbox2008
# 2018-06-08
#-------------------------------
#脚本在nova控制节点172.16.100.70执行

#1.创建数据库nova_placement,ova_api, nova, and nova_cell0 databases:
mysql -h 172.16.100.70 -uroot -p123456 -e" CREATE DATABASE  nova_placement;CREATE DATABASE  nova_cell0;CREATE DATABASE  nova;CREATE DATABASE  nova_api;flush privileges; \q;"

#进入数据库后，执行授权：
mysql -h 172.16.100.70 -uroot -p123456 -e "GRANT ALL PRIVILEGES ON nova_placement.* TO 'nova'@'localhost'  IDENTIFIED BY 'NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova_placement.* TO 'nova'@'%'   IDENTIFIED BY 'NOVA_DBPASS'; \q;"
mysql -h 172.16.100.70 -uroot -p123456 -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost'  IDENTIFIED BY 'NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%'   IDENTIFIED BY 'NOVA_DBPASS';\q;"
mysql -h 172.16.100.70 -uroot -p123456 -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost'  IDENTIFIED BY 'NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%'   IDENTIFIED BY 'NOVA_DBPASS';\q;"
mysql -h 172.16.100.70 -uroot -p123456 -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost'  IDENTIFIED BY 'NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%'   IDENTIFIED BY 'NOVA_DBPASS';\q;"

#2.在上创建nova服务
#（0）加载环境变量
source ~/admin-openrc 

#(1)创建nova用户
openstack user create --domain default  --description "nova user" --password 123456 nova

#(2）添加用户角色，给nova用户添加admin权限
openstack role add --project service --user nova admin

#(3）创建名称为nova的计算服务
openstack service create --name nova  --description "Openstack Compute" compute

#（4）创建placement用户
openstack user create --domain default --description "nova user"  --password 123456 placement

#（5）赋予admin权限
openstack role add --project service --user placement admin

#（6）创建名称为placement的placemnet服务
openstack service create --name placement --description "Placement API" placement

#3.创建compute服务三个API端点public,internal,admin
#(1).public API端点
openstack endpoint create --region RegionOne  compute public http://172.16.100.70:8774/v2.1

#(2).internal API端点
openstack endpoint create --region RegionOne  compute internal http://172.16.100.70:8774/v2.1

#(3).admin API端点
openstack endpoint create --region RegionOne  compute admin http://172.16.100.70:8774/v2.1


#4.创建placement服务三个API端点public,internal,admin
#(1).public API端点
openstack endpoint create --region RegionOne placement public http://172.16.100.70:8778

#(2).internal API端点
openstack endpoint create --region RegionOne placement internal http://172.16.100.70:8778

#(3).admin API端点
openstack endpoint create --region RegionOne placement admin http://172.16.100.70:8778

#5.安装openstack nova相软件包
yum -y install openstack-nova-api 
yum -y install openstack-nova-conductor 
yum -y install openstack-nova-console openstack-nova-novncproxy
yum -y install openstack-nova-scheduler openstack-nova-placement-api 


#6.修改配置文件/etc/nova/nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.bak_$(date +%F_%T)
#（1）修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\enabled_apis = osapi_compute,metadata' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\transport_url = rabbit://openstack:RABBIT_PASS@172.16.100.70' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\my_ip = 172.16.100.70' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\use_neutron = True' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\firewall_driver = nova.virt.firewall.NoopFirewallDriver' /etc/nova/nova.conf

#（2）修改---[api_database]选项
sed -i '/^\[api_database\]/a\connection = mysql+pymysql://nova:NOVA_DBPASS@172.16.100.70/nova_api' /etc/nova/nova.conf

#（3）修改---[database]选项
sed -i '/^\[database\]/a\connection = mysql+pymysql://nova:NOVA_DBPASS@172.16.100.70/nova' /etc/nova/nova.conf

#(4)修改---[keystone_authtoken]选项
sed -i '/^\[keystone_authtoken\]/a\auth_uri = http://172.16.100.70:5000' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\auth_url = http://172.16.100.70:35357' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\memcached_servers = 172.16.100.70:11211' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\auth_type = password' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\project_domain_name = default' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\user_domain_name = default' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\project_name = service' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\username = nova' /etc/nova/nova.conf
sed -i '/^\[keystone_authtoken\]/a\password = 123456' /etc/nova/nova.conf

#(5)修改---[api]选项
sed -i '/^\[api\]/a\auth_strategy = keystone' /etc/nova/nova.conf


#(6)修改---[vnc]选项
sed -i '/^\[vnc\]/a\enabled = true' /etc/nova/nova.conf
sed -i '/^\[vnc\]/a\vncserver_listen = $my_ip' /etc/nova/nova.conf
sed -i '/^\[vnc\]/a\vncserver_proxyclient_address = $my_ip' /etc/nova/nova.conf

#(7)修改---[glance]选项
sed -i '/^\[glance\]/a\api_servers = http://172.16.100.70:9292' /etc/nova/nova.conf

#(8)修改---[oslo_concurrency]选项
sed -i '/^\[oslo_concurrency\]/a\lock_path = /var/lib/nova/tmp' /etc/nova/nova.conf

#(9)修改---[placement]选项
sed -i '/^\[placement\]/a\os_region_name = RegionOne' /etc/nova/nova.conf
sed -i '/^\[placement\]/a\project_domain_name = Default' /etc/nova/nova.conf
sed -i '/^\[placement\]/a\project_name = service' /etc/nova/nova.conf
sed -i '/^\[placement\]/a\auth_type = password' /etc/nova/nova.conf
sed -i '/^\[placement\]/a\user_domain_name = Default' /etc/nova/nova.conf
sed -i '/^\[placement\]/a\auth_url = http://172.16.100.70:35357/v3' /etc/nova/nova.conf
sed -i '/^\[placement\]/a\username = placement' /etc/nova/nova.conf
sed -i '/^\[placement\]/a\password = 123456' /etc/nova/nova.conf


#(10)写入00-nova-placement-api.conf配置文件
cp /etc/httpd/conf.d/00-nova-placement-api.conf /etc/httpd/conf.d/00-nova-placement-api.conf.bak_$(date +%F_%T)

cat >/etc/httpd/conf.d/00-nova-placement-api.conf <<eof
Listen 8778
<VirtualHost *:8778>
  WSGIProcessGroup nova-placement-api
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
  WSGIDaemonProcess nova-placement-api processes=3 threads=1 user=nova group=nova
  WSGIScriptAlias / /usr/bin/nova-placement-api
<IfVersion >= 2.4>
    ErrorLogFormat "%M"
</IfVersion>
  ErrorLog /var/log/nova/nova-placement-api.log
  #SSLEngine On
  #SSLCertificateFile ...
  #SSLCertificateKeyFile ...
<Directory /usr/bin>
    Require all granted
</Directory>
</VirtualHost>

Alias /nova-placement-api /usr/bin/nova-placement-api
<Location /nova-placement-api>
  SetHandler wsgi-script
  Options +ExecCGI
  WSGIProcessGroup nova-placement-api
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
</Location>
eof


#(11)重启httpd服务
systemctl restart httpd

#(12)同步数据库
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova

#(12)查看
nova-manage cell_v2 list_cells

#（13）启动服务并设置开机启动
systemctl enable openstack-nova-api.service 
systemctl enable openstack-nova-consoleauth.service openstack-nova-scheduler.service
systemctl enable openstack-nova-conductor.service openstack-nova-novncproxy.service
  
systemctl start openstack-nova-api.service 
systemctl start openstack-nova-consoleauth.service openstack-nova-scheduler.service 
systemctl start openstack-nova-conductor.service openstack-nova-novncproxy.service


#7.验证安装完计算节点后执行

#(0)发现计算节点
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

#(1)查看服务
openstack compute service list

#(2)在openstack keystone中列出API的endpoint，验证所有端点服务是否与keystone服务的连接正常
openstack catalog list

#（3）验证cells and placement API 是否正常
nova-status upgrade check


















