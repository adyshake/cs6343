import os

def runCommand(command):
    stream = os.popen(command)
    return stream.read()

#OS config
LINE_ENDING = '\n'

#Ceph Config
CEPH_DATA_POOL = 'demo_cephfs_data'
CEPH_META_POOL = 'demo_cephfs_meta'
CEPH_FILE_SYSTEM = 'demo_cephfs' 
CEPH_FILE_SYSTEM_PATH = '/mnt/demo_cephfs'

#Ceph Commands
CEPH_LIST_OBJECTS = 'rados -p ' + CEPH_DATA_POOL + ' ls'
CEPH_OSD_TREE = 'ceph osd tree'

listOfObjects = runCommand('ls -1').split(LINE_ENDING)
if listOfObjects[-1] == '':
    listOfObjects = listOfObjects[:-1]

print("List of objects: " + listOfObjects)

osdStatus = runCommand(CEPH_OSD_TREE).split(LINE_ENDING)

print("OSD status: " + listOfObjects)

