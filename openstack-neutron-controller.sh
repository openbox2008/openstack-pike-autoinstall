#!/bin/bash
#-------------------------------
# install openstack neutron for controller
# by openbox2008
# 2018-06-08
#-------------------------------

#脚本在控制节点172.16.100.70上执行

#1.创建数据库nova_placement,ova_api, nova, and nova_cell0 databases:
mysql -h 172.16.100.70 -uroot -p123456 -e" CREATE DATABASE neutron;flush privileges;\q;"

#进入数据库后，执行授权：
mysql -h 172.16.100.70 -uroot -p123456 -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost'   IDENTIFIED BY 'NEUTRON_DBPASS'; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%'   IDENTIFIED BY 'NEUTRON_DBPASS';\q;"

#2.在控制节点上安装和配置neutron服务
#（1）创建neutron用户
openstack user create --domain default --description "neutron user" --project service --password 123456 neutron 

#(2)赋予neutron用户admin权限
openstack role add --project service --user neutron admin

#(3)创建服务
openstack service create --name neutron --description "OpenStack Networking service" network 

#3.创建compute服务三个API端点public,internal,admin
#(1).public API端点
openstack endpoint create --region RegionOne network public http://172.16.100.70:9696 

#(2).internal API端点
openstack endpoint create --region RegionOne network internal http://172.16.100.70:9696 

#(3).admin API端点
openstack endpoint create --region RegionOne network admin http://172.16.100.70:9696 

#4.安装openstack neutron相软件包
yum  -y install openstack-neutron openstack-neutron-ml2

#5.修改配置文件/etc/neutron/neutron.conf
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak_$(date +%F_%T)

#（1）修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\core_plugin = ml2' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\service_plugins = router' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\auth_strategy = keystone' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\state_path = /var/lib/neutron' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\dhcp_agent_notification = True' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\allow_overlapping_ips = True' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\notify_nova_on_port_status_changes = True' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\notify_nova_on_port_data_changes = True' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\transport_url = rabbit://openstack:RABBIT_PASS@172.16.100.70' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\##' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/neutron.conf


#（2）修改---[database]选项
sed -i '/^\[database\]/a\connection = mysql+pymysql://neutron:NEUTRON_DBPASS@172.16.100.70/neutron' /etc/neutron/neutron.conf
sed -i '/^\[database\]/a\##' /etc/neutron/neutron.conf
sed -i '/^\[database\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[database\]/a\#' /etc/neutron/neutron.conf


#(3) 修改---[keystone_authtoken]选项
sed -i '/^\[keystone_authtoken\]/a\auth_uri = http://172.16.100.70:5000' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\auth_url = http://172.16.100.70:35357' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\memcached_servers = 172.16.100.70:11211' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\auth_type = password' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\project_domain_name = default' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\user_domain_name = default' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\project_name = service' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\username = neutron' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\password = 123456' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\##' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\#' /etc/neutron/neutron.conf


#(4) 修改---[nova]选项
sed -i '/^\[nova\]/a\auth_url = http://172.16.100.70:35357' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\auth_type = password' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\project_domain_name = default' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\user_domain_name = default' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\region_name = RegionOne' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\project_name = service' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\username = nova' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\password = 123456' /etc/neutron/neutron.config
sed -i '/^\[nova\]/a\##' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[nova\]/a\#' /etc/neutron/neutron.conf


#(5)修改---[oslo_concurrency]选项
sed -i '/^\[oslo_concurrency\]/a\lock_path = $state_path/tmp' /etc/neutron/neutron.conf
sed -i '/^\[oslo_concurrency\]/a\##' /etc/neutron/neutron.conf
sed -i '/^\[oslo_concurrency\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[oslo_concurrency\]/a\#' /etc/neutron/neutron.conf

#(6)赋予权限
chmod 640 /etc/neutron/neutron.conf 
chgrp neutron /etc/neutron/neutron.conf 

#6.修改配置metadata文件/etc/neutron/metadata_agent.ini
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak_$(date +%F_%T)
#(1)修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\nova_metadata_host = 172.16.100.70' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\metadata_proxy_shared_secret = 123456' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/metadata_agent.ini

#(2)修改---[cache]选项
sed -i '/^\[cache\]/a\memcache_servers = 172.16.100.70:11211' /etc/neutron/metadata_agent.ini
sed -i '/^\[cache\]/a\#' /etc/neutron/metadata_agent.ini
sed -i '/^\[cache\]/a\#' /etc/neutron/metadata_agent.ini
sed -i '/^\[cache\]/a\#' /etc/neutron/metadata_agent.ini

#7.修改配置ml2文件/etc/neutron/plugins/ml2/ml2_conf.ini
cp -a  /etc/neutron/plugins/ml2/ml2_conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini.bak_$(date +%F_%T)

#(1)修改---[ml2]选项
sed -i '/^\[ml2\]/a\type_drivers = flat,vlan,gre,vxlan' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2\]/a\tenant_network_types =' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2\]/a\mechanism_drivers = openvswitch,l2population' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2\]/a\extension_drivers = port_security' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini

#(2)修改---[securitygroup]选项
sed -i '/^\[securitygroup\]/a\enable_security_group = True' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[securitygroup\]/a\firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[securitygroup\]/a\enable_ipset = True' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[securitygroup\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[securitygroup\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini


#8.重新修改配置nova文件/etc/nova/nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.bak_$(date +%F_%T)
#(1)修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\use_neutron = True' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\firewall_driver = nova.virt.firewall.NoopFirewallDriver' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\#' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\#' /etc/nova/nova.conf

#(2)修改---[neutron]选项
sed -i '/^\[neutron\]/a\url = http://172.16.100.70:9696' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\auth_url = http://172.16.100.70:35357' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\auth_type = password' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\project_domain_name = default' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\user_domain_name = default' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\region_name = RegionOne' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\project_name = service' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\username = neutron' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\password = 123456' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\service_metadata_proxy = True' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\metadata_proxy_shared_secret = 123456' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\#' /etc/nova/nova.conf
sed -i '/^\[neutron\]/a\#' /etc/nova/nova.conf


#9.创建软连接
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 

#10.同步数据库
su -s /bin/bash neutron -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head" 

#11.启动neutron服务
systemctl start neutron-server neutron-metadata-agent 
systemctl enable neutron-server neutron-metadata-agent 

#重启openstack-nova-api 
systemctl restart openstack-nova-api
