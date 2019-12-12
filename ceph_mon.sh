
//----------------Create new filesystem---------------------

ceph osd pool create demo_cephfs_data 128
ceph osd pool create demo_cephfs_meta 128

ceph osd pool set demo_cephfs_data size 2
ceph osd pool set demo_cephfs_meta size 2

ceph fs new demo_cephfs demo_cephfs_meta demo_cephfs_data

//List file system
ceph fs ls

//To get replicated size of pools
ceph osd dump | grep 'replicated size'

sudo mkdir /mnt/demo_cephfs
sudo ceph-fuse /mnt/demo_cephfs

rados -p demo_cephfs_data ls

ceph osd map demo_cephfs_data object1

//----------How placement group ID is generated-------------
/*
input = pool_name, object_id
hash = hash(object_id)
pg_id = hash % 128 //58
pool_id = getPoolID(pool_name) //4
pg_id = pool_id + "." + pg_id //4.58
*/

//-------------Deleting a filesystem on Ceph---------------

//List file system
ceph fs ls

//Delete file system
systemctl stop ceph-mds.target
ceph mds fail 0 && ceph fs rm cepfs_data --yes-i-really-mean-it
systemctl start ceph-mds.target

//Verify its gone
ceph fs ls

//Allow pool deletions from monitor
ceph tell mon.\* injectargs '--mon-allow-pool-delete=true'

//Delete associated pools
ceph osd pool delete cephfs_data cephfs_data --yes-i-really-really-mean-it
ceph osd pool delete cephfs_meta cephfs_meta --yes-i-really-really-mean-it

//Disable pool deletions
ceph tell mon.\* injectargs '--mon-allow-pool-delete=false'