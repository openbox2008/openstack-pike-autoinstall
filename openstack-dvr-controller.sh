#!/bin/bash
#-------------------------------
# create openstack dvr network
# by openbox2008
# 2018-06-08
#-------------------------------
#在控制，网络，计算节点手动执行,分布式虚拟路由器

#1.删除原来的路由器和网络

#2.在控制节点修改配置文件：
openstack-config --set /etc/neutron/neutron.conf DEFAULT router_distributed True

#3.在网络节点修改配置文件：
#(1)修改/etc/neutron/plugins/ml2/openvswitch_agent.ini
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini DEFAULT enable_distributed_routing True

#(2)修改/etc/neutron/l3_agent.ini
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT agent_mode dvr_snat

#4.在计算节点修改配置文件：
# cp -a /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini_bak
#(1).修改配置文件/etc/neutron/l3_agent.ini
openstack-config --set  /etc/neutron/l3_agent.ini DEFAULT interface_driver  neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set  /etc/neutron/l3_agent.ini DEFAULT agent_mode  dvr 

#(2).修改配置文件/etc/neutron/plugins/ml2/openvswitch_agent.ini
openstack-config --set  /etc/neutron/plugins/ml2/openvswitch_agent.ini DEFAULT enable_distributed_routing  True
openstack-config --set  /etc/neutron/plugins/ml2/openvswitch_agent.ini  ovs bridge_mappings  physnet1:br-eth1


#（3）在计算节点创建ovs网桥
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 em2

#(4).计算节点上重启 neutron-l3-agent服务（默认没开启）
systemctl restart neutron-l3-agent.service
systemctl enable neutron-l3-agent.service


#5.重启服务
#（1）计算节点
systemctl restart neutron-l3-agent.service neutron-openvswitch-agent.service

#（2）网络节点
systemctl restart neutron-dhcp-agent.service neutron-l3-agent.service  neutron-metadata-agent.service neutron-openvswitch-agent.service

#（3）控制节点
systemctl restart neutron-metadata-agent.service neutron-server.service


#6.重新创建网络和虚拟服务器

