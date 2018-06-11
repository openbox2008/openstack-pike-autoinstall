#!/bin/bash
#-------------------------------
# install openstack neutron for network
# by openbox2008
# 2018-06-08
#-------------------------------


#脚本在network节点172.16.100.71安装和配置

#1.安装软件在包
yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch

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

#3.修改配置l3_agent文件/etc/neutron/l3_agent.ini
cp -a  /etc/neutron/l3_agent.ini  /etc/neutron/l3_agent.ini.bak_$(date +%F_%T)
#(1)修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver' /etc/neutron/l3_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/l3_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/l3_agent.ini

#4.修改配置dhcp_agent文件/etc/neutron/dhcp_agent.ini
cp -a  /etc/neutron/dhcp_agent.ini  /etc/neutron/dhcp_agent.ini.bak_$(date +%F_%T)
#(1)修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver' /etc/neutron/dhcp_agent.ini
sed -i '/^\[DEFAULT\]/a\dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq' /etc/neutron/dhcp_agent.ini
sed -i '/^\[DEFAULT\]/a\enable_isolated_metadata = True' /etc/neutron/dhcp_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/dhcp_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/dhcp_agent.ini

#5.修改配置metadata_agent文件/etc/neutron/metadata_agent.ini
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak_$(date +%F_%T)
#(1)修改---[DEFAULT]选项
sed -i '/^\[DEFAULT\]/a\nova_metadata_host = 172.16.100.70' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\metadata_proxy_shared_secret = 123456' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/metadata_agent.ini

#(2)修改---[cache]选项
sed -i '/^\[cache\]/a\memcache_servers = 172.16.100.70:11211' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/metadata_agent.ini
sed -i '/^\[DEFAULT\]/a\#' /etc/neutron/metadata_agent.ini

#6.修改配置ml2文件/etc/neutron/plugins/ml2/ml2_conf.ini
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

#7.创建软连接
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 

#8.启动ovs服务
systemctl start openvswitch 
systemctl enable openvswitch 

#9.在ovs中创建内网网桥
#在此处创建一个内网网桥，br-inside1是ovs网桥名,后面还要定义一个br-outside1的外部网桥，并且该网桥做为租户承载网overlay，绑定物理网卡em2，可以上网
ovs-vsctl add-br br-int

#10.启动服务并设置开机启动
systemctl restart neutron-dhcp-agent
systemctl restart neutron-l3-agent
systemctl restart neutron-metadata-agent
systemctl restart neutron-openvswitch-agent

systemctl enable neutron-dhcp-agent
systemctl enable neutron-l3-agent
systemctl enable neutron-metadata-agent
systemctl enable neutron-openvswitch-agent

systemctl status neutron-dhcp-agent
systemctl status neutron-l3-agent
systemctl status neutron-metadata-agent
systemctl status neutron-openvswitch-agent