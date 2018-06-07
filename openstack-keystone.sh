#!/bin/bash
#-------------------------------
# install openstack keystone
# by openbox2008
# 2018-06-06
#-------------------------------

#1.在mariadb上为keystone创建管理数据库：

#去到管理数据库上，以 root 用户连接到数据库服务器：1.创建 keystone 数据库：
mysql -h 172.16.100.70 -uroot -p123456 -e "CREATE DATABASE keystone;\q;"
#2.对`keystone`数据库授予恰当的权限：
mysql -h 172.16.100.70 -uroot -p123456 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';\q;"

#2.在控制节点上安装keystone
yum -y install openstack-keystone httpd mod_wsgi

#编辑文件 /etc/keystone/keystone.conf 
cp /etc/keystone/keystone.conf  /etc/keystone/keystone.conf.bak

#在`[DEFAULT]`部分，定义初始管理令牌的值：
#可以使用 openssl rand -hex 10 生成的随机数替换`ADMIN_TOKEN` 值。
ad_token=openssl rand -hex 10
sed -i "[DEFAULT]/a\admin_token = $ad_token"  /etc/keystone/keystone.conf
      
#在 [database] 部分，配置数据库访问：
sed -i '[database]/a\connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@172.16.100.70/keystone' /etc/keystone/keystone.conf

#在`[token]`部分，配置Fernet UUID令牌的提供者。
sed -i '[token]/a\provider = fernet' /etc/keystone/keystone.conf
sed -i '[token]/a\driver = memcache' /etc/keystone/keystone.conf

#为keystone配置memcache服务
#在keystone.conf 文件中找到以下相关选项memcache_servers ，和driver并按下面的值修改
sed -i '[cache]/a\memcache_servers = 172.16.100.70:11211' /etc/keystone/keystone.conf


#3.在keystone上同步认证服务的数据库：
su -s /bin/sh -c "keystone-manage db_sync" keystone

#检查数据库连接：mysql -h 172.16.100.70 -ukeystone -pKEYSTONE_DBPASS -e "use keystone;show tables;"

#4.初始化keystone Fernet keys密匙：
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

#初始化后创建/etc/keystone/fernet-keys目录，里面有KEY文件

#5.配置keystone引导身份服务
keystone-manage bootstrap \
--bootstrap-password ADMIN_PASS \
--bootstrap-admin-url http://172.16.100.70:35357/v3/ \
--bootstrap-internal-url http://172.16.100.70:5000/v3/ \
--bootstrap-public-url http://172.16.100.70:5000/v3/ \
--bootstrap-region-id RegionOne

#keystone管理员密码为ADMIN_PASS，可以更改。

#6.在keystone上配置 Apache HTTP 服务器：

#编辑/etc/httpd/conf/httpd.conf 文件，配置`ServerName` 选项为控制节点：#keystone配置apache的ServerName,不然起不来
sed -i 'ServerName/a\ServerName 172.16.100.70' /etc/httpd/conf/httpd.conf

#7.在apache目录下创建keystone配置文件，将keystone在apache中的配置文件软链接到apache目录下
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

#8.重启httpd服务
systemctl enable httpd
systemctl restart httpd

#8.创建openstack 客户端环境脚本
#创建admin-openrc脚本
cat > ~/admin-openrc << eof
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=http://172.16.100.70:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
eof

#创建demo-openrc脚本，vim /root/demo-openrc
cat > ~/demo-openrc <<eof
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=123456
export OS_AUTH_URL=http://172.16.100.70:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
eof

#只有root用户才有读写权限
chmod 600 /root/admin-openrc   
chmod 600 /root/demo-openrc 

#执行脚本
source ~/admin-openrc 

#9创建域domain、项目projects、用户users和角色roles
#（1.）创建域domain
openstack domain create --description "Domain" example

#（2.）创建名为service的项目
openstack project create --domain default --description "Service Project" service

#（3.）创建平台demo项目
openstack project create --domain default --description "Demo Project" demo

#（4.）创建demo用户#password:123456
openstack user create --domain default  --password 123456 demo  

#（5.）创建用户角色
openstack role create user

#（6.）添加用户角色，给demo用户增加user权限
openstack role add --project demo --user demo user


#10.验证安装
openstack token issue
openstack role list












