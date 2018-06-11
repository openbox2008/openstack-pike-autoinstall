#!/bin/bash
#-------------------------------
# install openstack vxlan for controller
# by openbox2008
# 2018-06-08
#-------------------------------

#脚本在控制节点172.16.100.70上执行

#1.修改配置文件/etc/neutron/plugins/ml2/ml2_conf.ini
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak_$(date +%F_%T)

#(1)修改---[ml2]选项
sed -i 's/^tenant_network_types =/tenant_network_types = vxlan/' /etc/neutron/plugins/ml2/ml2_conf.ini

#(2)修改---[ml2_type_flat]选项
sed -i '/^\[ml2_type_flat\]/a\flat_networks = physnet1' /etc/neutron/plugins/ml2/ml2_conf.ini

#(3)修改---[ml2_type_vxlan]选项
sed -i '/^\[ml2_type_vxlan\]/a\vni_ranges = 1:1000' /etc/neutron/plugins/ml2/ml2_conf.ini


#2.重启服务
systemctl restart neutron-server 
