#!/bin/bash
#-------------------------------
# install openstack vxlan for compute
# by openbox2008
# 2018-06-08
#-------------------------------
#脚本在compute计算节点172.16.100.72~74执行


#1.修改配置文件/etc/neutron/plugins/ml2/ml2_conf.ini
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak_$(date +%F_%T)

#(1)修改---[ml2]选项
sed -i 's/^tenant_network_types =/tenant_network_types = vxlan/' /etc/neutron/plugins/ml2/ml2_conf.ini

#(2)修改---[ml2_type_flat]选项
sed -i '/^\[ml2_type_flat\]/a\flat_networks = physnet1' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2_type_flat\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2_type_flat\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini

#(3)修改---[ml2_type_vxlan]选项
sed -i '/^\[ml2_type_vxlan\]/a\vni_ranges = 1:1000' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2_type_vxlan\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^\[ml2_type_vxlan\]/a\#' /etc/neutron/plugins/ml2/ml2_conf.ini

#2.修改配置文件/etc/neutron/plugins/ml2/openvswitch_agent.ini
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak_$(date +%F_%T)

#(1)修改---[agent]选项
sed -i '/^\[ml2_type_vxlan\]/a\tunnel_types = vxlan' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\l2_population = True' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\prevent_arp_spoofing = True' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini

#(2)修改---[ovs]选项
#当前节点的管理网IP,每个计算节点都要更换自已的IP
sed -i '/^\[ovs\]/a\local_ip = 172.16.100.72' /etc/neutron/plugins/ml2/openvswitch_agent.ini

#physnet1之前定义的二层网络名称，br-outside1是在前面定义的ovs网桥名,这个网桥映射到ovs交换机中，该网桥做为租户承载网overlay，绑定物理网卡em2，可以上网
sed -i '/^\[ovs\]/a\bridge_mappings = physnet1:br-outside1' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ovs\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ovs\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini

#3.重启OVS服务
systemctl restart neutron-openvswitch-agent


