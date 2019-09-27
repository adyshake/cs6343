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
usermod -aG wheel username
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
   User cent\n" \
> ~/.ssh/config 

chmod 644 ~/.ssh/config
ssh-copy-id mon1
ssh-copy-id osd1

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
ceph-deploy install ceph-admin mon1 osd1

#Deploy initial monitor
ceph-deploy mon create-initial
