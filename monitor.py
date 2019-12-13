import os
import time
import collections

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
CEPH_DOWN_KEYWORD = 'down'
CEPH_UP_KEYWORD = 'up'

OSD_VM_MAP = {0:'pc1_vm2', 1:'pc1_vm3', 2:'pc3_vm1'}

#Ceph Commands
CEPH_LIST_OBJECTS = 'rados -p ' + CEPH_DATA_POOL + ' ls'
CEPH_OSD_TREE = 'ceph osd tree'
CEPH_OSD_MAP = 'ceph osd map'

listOfObjects = runCommand(CEPH_LIST_OBJECTS).split(LINE_ENDING)[:-1]

print("List of objects: " + str(listOfObjects))

osdMap = {}

def initOSDMap():
    osdStatus = runCommand(CEPH_OSD_TREE).split(LINE_ENDING)[:-1]
    osdVMID = 0
    for line in osdStatus:
        lineSplit = line.split()
        if lineSplit[1] == 'hdd':
            hdd = lineSplit[3].split('.')[1]
            status = lineSplit[4]
            osdMap[OSD_VM_MAP[osdVMID]] = {'osdID': hdd, 'status': status, 'objects': []}
            print(osdMap[OSD_VM_MAP[osdVMID]])
            osdVMID = osdVMID + 1

initOSDMap()

def getOSDList(objectID):
    ceph_get_pg_to_osd_mapping_command = 'ceph osd map ' + CEPH_DATA_POOL + ' ' + objectID
    output = runCommand(ceph_get_pg_to_osd_mapping_command)
    output = output.split(CEPH_UP_KEYWORD)
    first_paren = output[1].find('[')
    second_paren = output[1].find(']')
    if (first_paren == -1 or second_paren == -1):
        print('Couldn\'t find parentheses')
        exit()
    output = output[1][first_paren + 1:second_paren].strip()
    osdList = output.split(',')
    return osdList

#Time to get object list's pg maps
for objectID in listOfObjects:
    osdList = getOSDList(objectID)
    for osd in osdList:
        curOSDState = osdMap[OSD_VM_MAP[int(osd)]]
        curOSDState['objects'].append(objectID)
        osdMap[OSD_VM_MAP[int(osd)]] = curOSDState
        print(osdMap[OSD_VM_MAP[int(osd)]])


def updateOSDStateAndGetDowned():
    osdStatus = runCommand(CEPH_OSD_TREE).split(LINE_ENDING)[:-1]
    osdVMID = 0
    downedOSDs = []
    for line in osdStatus:
        lineSplit = line.split()
        if lineSplit[1] == 'hdd':
            hdd = lineSplit[3].split('.')[1]
            status = lineSplit[4]
            # print("Checking" + str(osdVMID) + status + osdMap[OSD_VM_MAP[osdVMID]]['status'])
            if status != osdMap[OSD_VM_MAP[osdVMID]]['status']:
                osdMap[OSD_VM_MAP[osdVMID]]['status'] = status
                if status == CEPH_DOWN_KEYWORD:
                    downedOSDs.append(osdVMID)
            osdVMID = osdVMID + 1
    return downedOSDs


downedOSDs = []
# Now we've captured the initial state of the system
while(True):
    downedOSDs = updateOSDStateAndGetDowned()
    if downedOSDs == []:
        print('Nothing\'s down yet')
        time.sleep(15)
    else:
        break

print('The follwoing nodes went down: ' + str(downedOSDs))

rebalanceSet = set()
for downedOSD in downedOSDs:
    objectList = osdMap[OSD_VM_MAP[int(downedOSD)]]['objects']
    print(objectList)
    for x in objectList:
        # rebalanceSet.add({'objectID': x, 'from': str(downedOSD), 'to': ''})
        rebalanceSet.add(x)
print(rebalanceSet)

deltaOSDMap = {}

def checkIfPlacementGroupChanged():
    rebalanceList = list(rebalanceSet)
    for objectID in rebalanceList:
        osdList = getOSDList(objectID)
        print("Fresh list arrived: " + str(osdList))
        if objectID in deltaOSDMap:
            curState = deltaOSDMap[objectID]
            print("Old list is: " + str(curState))
            if (collections.Counter(curState) != collections.Counter(osdList)):
                print('Object has been migrated!')
                # TODO - Make this more accurate
                # rebalJSON['from'] contains old downed. deltaOSDMap has whatever was left alive.
                # osdList contains the fresh osd list data
                # So, toOSD = osdList - deltaOSDMap[objectID]
                toOSD = [x for x in osdList if x not in curState]
                print(objectID + " migrated to " + str(toOSD))
                rebalanceSet.remove(objectID)
        else:
            deltaOSDMap[objectID] = osdList

while(len(rebalanceSet) != 0):
    checkIfPlacementGroupChanged()
    time.sleep(15)

print("All objects have been migrated")