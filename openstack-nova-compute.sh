#!/bin/bash
#-------------------------------
# install openstack nova for compute
# by openbox2008
# 2018-06-08
#-------------------------------

#脚本在compute计算节点172.16.100.72~74执行,注意更换“my_ip”地址

#1.其它计算节点上，安装nova计算节点软件包
yum -y install openstack-nova-compute

#2.修改配置文件/etc/nova/nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.bak_$(date +%F_%T)

#（1）修改---[DEFAULT]选项,注意修改my_ip的值
sed -i '/^\[DEFAULT\]/a\enabled_apis = osapi_compute,metadata' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\transport_url = rabbit://openstack:RABBIT_PASS@172.16.100.70' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\my_ip = 172.16.100.74' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\use_neutron = True' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a\firewall_driver = nova.virt.firewall.NoopFirewallDriver' /etc/nova/nova.conf

#（2）修改---[api_database]选项,与控制节点相比，此处不用修改
#sed -i '/^\[api_database\]/a\connection = mysql+pymysql://nova:NOVA_DBPASS@172.16.100.70/nova_api' /etc/nova/nova.conf

#（3）修改---[database]选项,与控制节点相比，此处不用修改
#sed -i '/^\[database\]/a\connection = mysql+pymysql://nova:NOVA_DBPASS@172.16.100.70/nova' /etc/nova/nova.conf

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
sed -i '/^\[vnc\]/a\vncserver_listen = 0.0.0.0' /etc/nova/nova.conf
sed -i '/^\[vnc\]/a\vncserver_proxyclient_address = $my_ip' /etc/nova/nova.conf
sed -i '/^\[vnc\]/a\novncproxy_base_url = http://172.16.100.70:6080/vnc_auto.html' /etc/nova/nova.conf

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

#(10)自动发现,修改---[scheduler]选项
sed -i '/^\[scheduler\]/a\discover_hosts_in_cells_interval = 300' /etc/nova/nova.conf

#3.启动服务并设置开机启动
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

#5.验证
source ~/admin-openrc
#(1)查看服务
openstack compute service list

#(2)在openstack keystone中列出API的endpoint，验证所有端点服务是否与keystone服务的连接正常
openstack catalog list































