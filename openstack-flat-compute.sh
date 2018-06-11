#!/bin/bash
#-------------------------------
# install openstack flat network for compute
# by openbox2008
# 2018-06-08
#-------------------------------

#脚本在计算 节点172.16.100.72~74上执行

#1.创建ovs网桥
ovs-vsctl add-br br-eth1 

#2.将物理业务网卡em2加入到br-eth1网桥中
ovs-vsctl add-port br-eth1 em2

#3.修改配置文件/etc/neutron/plugins/ml2/ml2_conf.ini
cp -a  /etc/neutron/plugins/ml2/ml2_conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini.bak_$(date +%F_%T)

#(1)修改---[ml2_type_flat]选项
sed -i '/^\[ml2_type_flat\]/a\flat_networks = physnet1' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2_type_flat\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2_type_flat\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini

#4.修改配置文件/etc/neutron/plugins/ml2/openvswitch_agent.ini
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak_$(date +%F_%T)
#(1)修改---[ovs]选项 ,映射虚拟网桥
sed -i '/^\[ovs\]/a\bridge_mappings = physnet1:br-eth1' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ovs\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ovs\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini

#5.重启服务
systemctl restart neutron-openvswitch-agent 
