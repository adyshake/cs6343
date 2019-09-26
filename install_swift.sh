
#Add the Openstack Stein repo
yum -y install centos-release-openstack-stein
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-OpenStack-stein.repo

# Install from Openstack Stein
yum --enablerepo=centos-openstack-stein -y install mariadb-server

    sed -i '/\[mysqld\]/a character-set-server=utf8' /etc/my.cnf

    systemctl start mariadb
    systemctl enable mariadb

    mysql_secure_installation
    #Type N for remove anonymous users

    mysql -u root -p
    #Enter password: 	# MariaDB root password you set

    firewall-cmd --add-service=mysql --permanent
    firewall-cmd --reload

yum --enablerepo=centos-openstack-stein -y install rabbitmq-server memcached

sed -i '/\[mysqld\]/a character-set-server=utf8' /etc/my.cnf.d/mariadb-server.cnf
# Default value 151 is not enough on Openstack Env
sed -i '/\[mysqld\]/a max_connections=500' /etc/my.cnf.d/mariadb-server.cnf

# Change line 5 to (listen all)
sed -i -e 's/OPTIONS=".*"/OPTIONS="-l 0.0.0.0,::"/g' /etc/sysconfig/memcached

systemctl restart mariadb rabbitmq-server memcached
systemctl enable mariadb rabbitmq-server memcached

rabbitmqctl add_user openstack cloudFuture-101
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

firewall-cmd --add-service=mysql --permanent
firewall-cmd --add-port={11211/tcp,5672/tcp} --permanent
firewall-cmd --reload

#Page 2

#Add a User and Database on MariaDB for Keystone.
mysql -u root -pcloudFuture-101 < add_user_and_database.sql

# install from Stein, EPEL
yum --enablerepo=centos-openstack-stein,epel -y install openstack-keystone openstack-utils python-openstackclient httpd mod_wsgi

# Specify Memcache server
sed -i '/memcache_servers/c\memcache_servers = 10.0.0.30:11211' /etc/keystone/keystone.conf

# Add MariaDB connection info
sed -i '/#connection=<None>/c\connection = mysql+pymysql://keystone:cloudFuture-101@10.0.0.30/keystone' /etc/keystone/keystone.conf

# Add provider
sed -i '/#provider=<None>/c\provider = fernet' /etc/keystone/keystone.conf

su -s /bin/bash keystone -c "keystone-manage db_sync"

# Initialize keys
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Define own host (controller host)
export controller=10.0.0.30

# Bootstrap keystone (replace any password you like for "adminpassword" section)
keystone-manage bootstrap --bootstrap-password cloudFuture-101 \
--bootstrap-admin-url http://$controller:5000/v3/ \
--bootstrap-internal-url http://$controller:5000/v3/ \
--bootstrap-public-url http://$controller:5000/v3/ \
--bootstrap-region-id RegionOne

# If SELinux is enabled, change boolean settings
setsebool -P httpd_use_openstack on
setsebool -P httpd_can_network_connect on
setsebool -P httpd_can_network_connect_db on

firewall-cmd --add-port=5000/tcp --permanent
firewall-cmd --reload

# Enable config for Keystone and start Apache httpd
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl start httpd
systemctl enable httpd

# Page 4