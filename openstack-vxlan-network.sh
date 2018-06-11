#!/bin/bash
#-------------------------------
# install openstack vxlan for network
# by openbox2008
# 2018-06-08
#-------------------------------

#脚本在network网络节点172.16.100.71上执行

#1.在ovs中创建网桥
#创建一个外网网桥,和之前定义的br-inside1内网网桥对应
ovs-vsctl add-br br-outside1

#2.将网卡加到网桥中
#该网桥做为租户承载网overlay，绑定物理网卡em2:172.16.70.71，可以上网. 不是管理网em1：172.16.100.71
ovs-vsctl add-port br-outside1 em2


#3.修改配置文件/etc/neutron/plugins/ml2/ml2_conf.ini
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

#4.修改配置文件/etc/neutron/plugins/ml2/openvswitch_agent.ini
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak_$(date +%F_%T)

#(1)修改---[agent]选项
sed -i '/^\[ml2_type_vxlan\]/a\tunnel_types = vxlan' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\l2_population = True' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\prevent_arp_spoofing = True' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ml2_type_vxlan\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini

#(2)修改---[ovs]选项
#当前网络节点的管理网IP
sed -i '/^\[ovs\]/a\local_ip = 172.16.100.71' /etc/neutron/plugins/ml2/openvswitch_agent.ini

#physnet1之前定义的二层网络名称，br-outside1是在前面定义的ovs网桥名,这个网桥映射到ovs交换机中，该网桥做为租户承载网overlay，绑定物理网卡em2，可以上网
sed -i '/^\[ovs\]/a\bridge_mappings = physnet1:br-outside1' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ovs\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i '/^\[ovs\]/a\#' /etc/neutron/plugins/ml2/openvswitch_agent.ini

#5.重启neutron服务
systemctl restart neutron-dhcp-agent
systemctl restart neutron-l3-agent
systemctl restart neutron-metadata-agent
systemctl restart neutron-openvswitch-agent



