sudo yum -y update
sudo yum -y install java-1.8.0-openjdk-devel
sudo echo -e "[cassandra]\nname=Apache Cassandra\nbaseurl=https://www.apache.org/dist/cassandra/redhat/311x/\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://www.apache.org/dist/cassandra/KEYS\n" > /etc/yum.repos.d/webmin.repo
sudo yum -y install cassandra
sudo systemctl enable cassandra
sudo systemctl start cassandra
nodetool status

#Configure cassandra.yaml
sudo sed -i 's/seeds: "127.0.0.1"/seeds: "10.0.0.122, 10.0.0.123, 10.0.0.124"/g' /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/listen_address: localhost/listen_address: $(hostname -I)/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/rpc_address: localhost/rpc_address: $(hostname -I)/g" /etc/cassandra/conf/cassandra.yaml
sudo echo 'auto_bootstrap: false' >> /etc/cassandra/conf/cassandra.yaml

sudo firewall-cmd --zone=public --add-port=7000/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9042/tcp --permanent
sudo firewall-cmd --reload

#To verify
sudo firewall-cmd --list-all

#To change cluster name
cqlsh $(hostname -I)
UPDATE system.local SET cluster_name = 'armd_cass' WHERE KEY = 'local';
exit
sudo sed -i "s/cluster_name: 'Test Cluster'/cluster_name: 'armd_cass'/g" /etc/cassandra/conf/cassandra.yaml
nodetool flush system
sudo systemctl restart cassandra
