#!/bin/bash
#-------------------------------
# install openstack neutron for compute
# by openbox2008
# 2018-06-08
#-------------------------------


#脚本在compute计算节点172.16.100.72~74执行

#1.安装软件包
yum  -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch


#2.修改配置neutron文件
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak_$(date +%F_%T)

#（1）修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\core_plugin = ml2' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\service_plugins = router' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\auth_strategy = keystone' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\state_path = /var/lib/neutron' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\allow_overlapping_ips = True' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\transport_url = rabbit://openstack:RABBIT_PASS@172.16.100.70' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/neutron.conf

#(2) 修改---[keystone_authtoken]选项
sed -i '/^\[keystone_authtoken\]/a\auth_uri = http://172.16.100.70:5000' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\auth_url = http://172.16.100.70:35357' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\memcached_servers = 172.16.100.70:11211' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\auth_type = password' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\project_domain_name = default' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\user_domain_name = default' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\project_name = service' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\username = neutron' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\password = 123456' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[keystone_authtoken\]/a\#' /etc/neutron/neutron.conf


#(3)修改---[oslo_concurrency]选项
sed -i '/^\[oslo_concurrency\]/a\lock_path = $state_path/tmp' /etc/neutron/neutron.conf
sed -i '/^\[oslo_concurrency\]/a\#' /etc/neutron/neutron.conf
sed -i '/^\[oslo_concurrency\]/a\#' /etc/neutron/neutron.conf

#(4)修改权限
chmod 640 /etc/neutron/neutron.conf 
chgrp neutron /etc/neutron/neutron.conf 


#3.修改配置ml2文件/etc/neutron/plugins/ml2/ml2_conf.ini
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

#4.重新修改配置nova文件/etc/nova/nova.conf
#(1)修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\use_neutron = True' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\firewall_driver = nova.virt.firewall.NoopFirewallDriver' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\vif_plugging_is_fatal = True' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\vif_plugging_timeout = 300' /etc/nova/nova.conf
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

#5.创建软连接
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 

#6.启动服务
systemctl start openvswitch 
systemctl enable openvswitch 

#7.创建内网网桥
ovs-vsctl add-br br-int

#8.启动compute服务
systemctl restart openstack-nova-compute 

#9.启动openvswitch-agent服务
systemctl start neutron-openvswitch-agent 
systemctl enable neutron-openvswitch-agent 

