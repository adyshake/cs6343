
//----------------Create new filesystem---------------------

ceph osd pool create demo_cephfs_data 128
ceph osd pool create demo_cephfs_meta 128

//3 -> demo_cephfs_data
//4 -> demo_cephfs_meta

ceph osd pool set demo_cephfs_data size 2
ceph osd pool set demo_cephfs_meta size 2

ceph fs new demo_cephfs demo_cephfs_meta demo_cephfs_data

//List file system
ceph fs ls

//To get replicated size of pools
ceph osd dump | grep 'replicated size'

sudo mkdir /mnt/demo_cephfs
sudo ceph-fuse /mnt/demo_cephfs

//----------------Beginning Test 1 - Check if balancing works---------------------

rados -p demo_cephfs_data ls
//10000000001.00000000

ceph osd map demo_cephfs_data 10000000001.00000000
//osdmap e99 pool 'demo_cephfs_data' (3) object '10000000001.00000000' -> pg 3.c9e0747 (3.47) -> up ([1,2], p1) acting ([1,2], p1)

ceph osd tree
ID CLASS WEIGHT  TYPE NAME     STATUS REWEIGHT PRI-AFF 
-1       0.17868 root default                          
-3       0.06149     host mon1                         
 0   hdd 0.06149         osd.0     up  1.00000 1.00000 //mon1 pc1_vm2
-5       0.06149     host osd1                         
 1   hdd 0.06149         osd.1   down        0 1.00000 //osd1 pc1_vm3
-7       0.05569     host osd7                         
 2   hdd 0.05569         osd.2     up  1.00000 1.00000 //osd7 pc3_vm1

Currently data is on pg 3.47 and its up on 1(pc1_vm3) and 2(pc3_vm1)

//Immediately after brinf 3(pc3_vm1) down
osdmap e102 pool 'demo_cephfs_data' (3) object '10000000001.00000000' -> pg 3.c9e0747 (3.47) -> up ([2], p2) acting ([2], p2)

//After waiting for some time for rebalancing to occur
osdmap e104 pool 'demo_cephfs_data' (3) object '10000000001.00000000' -> pg 3.c9e0747 (3.47) -> up ([2,0], p2) acting ([2,0], p2)

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
