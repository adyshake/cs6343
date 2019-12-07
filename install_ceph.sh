sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

cat << EOM > /etc/yum.repos.d/ceph.repo
[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-luminous/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
EOM

sudo yum update
sudo yum install ceph-deploy

sudo yum install ntp ntpdate ntp-doc
sudo yum install openssh-server

# Add a user for Ceph admin on all nodes
adduser cent
passwd cent
usermod -aG wheel cent
echo -e 'cent ALL = (root) NOPASSWD:ALL' | tee /etc/sudoers.d/cent
chmod 0440 /etc/sudoers.d/cent
firewall-cmd --add-service=ssh --permanent
firewall-cmd --reload

# Login as cent
exit
su cent

sudo echo -e \
"10.0.0.128 ceph-admin\n\
10.0.0.129 mon1\n\
10.0.0.130 osd1\n"\
"10.0.0.169 osd7\n"\
>> ~/etc/hosts

ssh-keygen

sudo echo -e \
"Host ceph-admin\n\
   Hostname ceph-admin\n\
   User cent\n\
Host mon1\n\
   Hostname mon1\n\
   User cent\n\
Host osd1\n\
   Hostname osd1\n\
   User cent\n\
Host osd7\n\
   Hostname osd7\n\
   User cent\n" \
> ~/.ssh/config 

chmod 644 ~/.ssh/config
ssh-copy-id mon1
ssh-copy-id osd1
ssh-copy-id osd7

#On monitor node
hostnamectl set-hostname mon1
sudo firewall-cmd --zone=public --add-service=ceph-mon --permanent
sudo firewall-cmd --reload

#On storage OSDs/MDSs
hostnamectl set-hostname osd1
sudo firewall-cmd --zone=public --add-service=ceph --permanent
sudo firewall-cmd --reload

sudo setenforce 0

sudo yum install yum-plugin-priorities

#Reboot into newly created ceph user on admin node

mkdir cluster
cd cluster

#Make sure to run this command without sudo or logged in as root!
ceph-deploy new mon1

#Add the following data to the newly created ceph.conf file

public network = 10.0.0.1/24

#Optional: Decides replication factor
osd pool default size = 2

#Install ceph on all nodes (I skipped ceph-admin, should probably include it)
ceph-deploy install ceph-admin mon1 osd1 osd7

#Deploy initial monitor
ceph-deploy mon create-initial

ceph-deploy admin ceph-admin mon1 osd1 osd7

ceph-deploy mgr create mon1

ceph-deploy osd create --data /dev/sdb mon1

ceph-deploy osd create --data /dev/sdb osd1

ceph-deploy osd create --data /dev/sdb osd7

#Will return a warning even though we had 14 gigs free, seems it's calibrated for cloud values lol
ssh mon1 sudo ceph health

#Create an Metadata server on the mon1 node
ceph-deploy mds create mon1

#Run this command on all nodes otherwise 'ceph' commands will fail
sudo chmod 644 /etc/ceph/ceph.client.admin.keyring

#Installing CephFS
ceph osd pool create cephfs_data 32
ceph osd pool create cephfs_meta 32
ceph fs new mycephfs cephfs_meta cephfs_data

#Optional : If OSDs are < 3
ceph osd pool set cephfs_data size 2
ceph osd pool set cephfs_meta size 2

sudo yum install ceph-fuse

sudo mkdir /mnt/cephfs
sudo ceph-fuse /mnt/cephfs

# -----------------------------------

#This is to specify placement group numbers which is a mandatory requirement. For less than 5 OSDs, it is 128 
ceph osd pool create mytest 128

rados put test-object-1  ./textfile.txt --pool=mytest

rados -p mytest ls

#Idenitifies the object location
ceph osd map mytest test-object1