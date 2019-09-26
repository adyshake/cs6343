# Add a user for Ceph admin on all nodes
echo -e 'Defaults:cent !requiretty\ncent ALL = (root) NOPASSWD:ALL' | tee /etc/sudoers.d/ceph
chmod 440 /etc/sudoers.d/ceph
firewall-cmd --add-service=ssh --permanent
firewall-cmd --reload

# Login as cent
logout
su cent

ssh-keygen
vim ~/.ssh/config

# Create new ( define all nodes and users )
Host dlp
    Hostname 10.0.0.128
    User cent
Host node01
    Hostname 10.0.0.129
    User cent
Host node02
    Hostname 10.0.0.130
    User cent
Host node03
    Hostname 10.0.0.148
    User cent


chmod 600 ~/.ssh/config
ssh-copy-id node01
ssh-copy-id node02
ssh-copy-id node03


sudo yum -y install epel-release centos-release-ceph-nautilus centos-release-openstack-stein
sudo yum -y install ceph-ansible
