#!/bin/bash

#set -x

#change to podman if testing on podman
RUNTIME=docker
#image name used for testing
IMG=permtestimage:0.0.1

#Build the image if needed.
$RUNTIME image inspect $IMG >/dev/null 2>&1 || $RUNTIME build . -t $IMG


#Create some volumes
$RUNTIME volume create permtestvol1 >/dev/null 2>&1
$RUNTIME volume create permtestvol2 >/dev/null 2>&1
$RUNTIME volume create permtestvol3 >/dev/null 2>&1
$RUNTIME volume create permtestvol4 >/dev/null 2>&1
$RUNTIME volume create permtestvol5 >/dev/null 2>&1
$RUNTIME volume create permtestvol6 >/dev/null 2>&1
$RUNTIME volume create permtestvol7 >/dev/null 2>&1
$RUNTIME volume create permtestvol8 >/dev/null 2>&1
$RUNTIME volume create permtestvol9 >/dev/null 2>&1
$RUNTIME volume create permtestvol10 >/dev/null 2>&1

# echo "Default mount permissions (no mounts)"
# $RUNTIME run --rm -ti --user 0:0 $IMG '/bin/bash' '-c' 'stat -c "%A $a %u %g %n" /* | grep -E "owned|restricted|doesnot"'

#Baseline.. run with 1/2/3/4/5/6 mounted to a/b/ra/rb/aa/dne
#This just sets up 1-6 to have various ownership/permissions based on their mountpoints
$RUNTIME run --rm -ti -v permtestvol1:/ownedbya -v permtestvol2:/ownedbyb -v permtestvol3:/restrictedtoa -v permtestvol4:/restrictedtob -v permtestvol5:/alsoownedbya -v permtestvol6:/doesnotexist --user 0:0 $IMG '/bin/bash' '-c' 'stat -c "%A $a %u %g %n" /* | grep -E "owned|restricted|notexist"' > firstmountperms.txt
#Swapped..  run with 1/2/3/4/5/6 mounted to b/a/rb/ra/dbe/aa
#Testing that mountpoint ownership overrides acquired ownership, except where acquired is being used against a non-existing mountpoint
$RUNTIME run --rm -ti -v permtestvol2:/ownedbya -v permtestvol1:/ownedbyb -v permtestvol4:/restrictedtoa -v permtestvol3:/restrictedtob -v permtestvol6:/alsoownedbya -v permtestvol5:/doesnotexist --user 0:0 $IMG '/bin/bash' '-c' 'stat -c "%A $a %u %g %n" /* | grep -E "owned|restricted|notexist"' > secondmountperms.txt
#Testing userid for non-existing mountpoint when running as non root uid/gid with fresh/used volume.
$RUNTIME run --rm -ti -v permtestvol7:/ownedbyb -v permtestvol2:/doesnotexist -v permtestvol8:/alsonotexist --user 1000:1000 $IMG '/bin/bash' '-c' 'stat -c "%A $a %u %g %n" /* | grep -E "owned|restricted|notexist"' > thirdmountperms.txt
#Testing userid for existing mountpoint is honored when running as non-root
$RUNTIME run --rm -ti -v permtestvol9:/ownedbyb -v paermtestvol6:/doesnotexist --user 1000:1000 $IMG '/bin/bash' '-c' 'stat -c "%A $a %u %g %n" /* | grep -E "owned|restricted|notexist"' > fourthmountperms.txt
#Testing userid for existing mountpoint is honored when running as non-root
$RUNTIME run --rm -ti -v permtestvol7:/doesnotexist --user 1000:1000 $IMG '/bin/bash' '-c' 'stat -c "%A $a %u %g %n" /* | grep -E "owned|restricted|notexist"' > fifthmountperms.txt

# verify fresh mounts to existing/non-existing mountpoints
FRESH_MOUNT_TO_EXISTING_RUNAS_ROOT_UIDGID=`grep "/alsoownedbya" firstmountperms.txt | cut -d' ' -s -f3,4`
FRESH_MOUNT_TO_EXISTINGA_RUNAS_ROOT_UIDGID=`grep "/ownedbya" firstmountperms.txt | cut -d' ' -s -f3,4`
FRESH_MOUNT_TO_EXISTINGB_RUNAS_ROOT_UIDGID=`grep "/ownedbyb" firstmountperms.txt | cut -d' ' -s -f3,4`

REUSED_MOUNT_TO_EXISTING_RUNAS_ROOT_UIDGID=`grep "/alsoownedbya" secondmountperms.txt | cut -d' ' -s -f3,4`
REUSED_MOUNT_TO_EXISTINGA_RUNAS_ROOT_UIDGID=`grep "/ownedbya" secondmountperms.txt | cut -d' ' -s -f3,4`
REUSED_MOUNT_TO_EXISTINGB_RUNAS_ROOT_UIDGID=`grep "/ownedbyb" secondmountperms.txt | cut -d' ' -s -f3,4`

FRESH_MOUNT_TO_NONEXIST_RUNAS_ROOT_UIDGID=`grep "/doesnotexist" firstmountperms.txt | cut -d' ' -s -f3,4`
FRESH_MOUNT_TO_NONEXIST_RUNAS_USERA_UIDGID=`grep "/alsonotexist" thirdmountperms.txt | cut -d' ' -s -f3,4`

REUSED_MOUNT_TO_NONEXIST_RUNAS_ROOT_UIDGID=`grep "/doesnotexist" secondmountperms.txt | cut -d' ' -s -f3,4`
REUSED_MOUNT_TO_NONEXIST_RUNAS_USERA_UID_GID=`grep "/doesnotexist" fifthmountperms.txt | cut -d' ' -s -f3,4`

REUSED_MOUNT_TO_EXISTING_RUNAS_ROOT_UIDGID=`grep "/ownedbya" secondmountperms.txt | cut -d' ' -s -f3,4`
REUSED_REUSED_MOUNT_TO_NONEXIST_RUNAS_USERA_UIDGID=`grep "/doesnotexist" thirdmountperms.txt | cut -d' ' -s -f3,4`

NONEXIST_TO_EXIST_TO_NONEXIST=`grep "/doesnotexist" fourthmountperms.txt | cut -d' ' -s -f3,4`


HONORS_EXISTING_MOUNT_OWNERSHIP_FOR_FRESH_VOLUMES="No"
if [ "$FRESH_MOUNT_TO_EXISTING_RUNAS_ROOT_UIDGID" == "1000 1000" ] && [ "$FRESH_MOUNT_TO_EXISTINGA_RUNAS_ROOT_UIDGID" == "1000 1000" ] && [ "$FRESH_MOUNT_TO_EXISTINGB_RUNAS_ROOT_UIDGID" == "2000 2000" ]; then 
  HONORS_EXISTING_MOUNT_OWNERSHIP_FOR_FRESH_VOLUMES="Yes"
fi

HONORS_EXISTING_MOUNT_OWNERSHIP_FOR_REUSED_VOLUMES="No"
if [ "$REUSED_MOUNT_TO_EXISTING_RUNAS_ROOT_UIDGID" == "1000 1000" ] && [ "$REUSED_MOUNT_TO_EXISTINGA_RUNAS_ROOT_UIDGID" == "1000 1000" ] && [ "$REUSED_MOUNT_TO_EXISTINGB_RUNAS_ROOT_UIDGID" == "2000 2000" ]; then 
  HONORS_EXISTING_MOUNT_OWNERSHIP_FOR_REUSED_VOLUMES="Yes"
fi

OWNERSHIP_OF_NONEXISTINGMOUNTS=$FRESH_MOUNT_TO_NONEXIST_RUNAS_ROOT_UIDGID
if [ "$FRESH_MOUNT_TO_NONEXIST_RUNAS_ROOT_UIDGID" == "0 0" ]; then
    if [ "$FRESH_MOUNT_TO_NONEXIST_RUNAS_USERA_UIDGID" == "0 0" ]; then
        OWNERSHIP_OF_NONEXISTINGMOUNTS="Root"
    elif [ "$FRESH_MOUNT_TO_NONEXIST_RUNAS_USERA_UIDGID" == "1000 1000" ]; then
        OWNERSHIP_OF_NONEXISTINGMOUNTS="Executing User"
    fi
fi

if [ "$REUSED_MOUNT_TO_NONEXIST_RUNAS_ROOT_UIDGID" == "1000 1000" ] && [ "$REUSED_MOUNT_TO_NONEXIST_RUNAS_USERA_UID_GID" == "2000 2000" ]; then
  REMEMBERS_OWNERSHIP_REUSED_TO_NONEXIST="Yes"
else
  REMEMBERS_OWNERSHIP_REUSED_TO_NONEXIST="No"
fi

if [ "$REUSED_MOUNT_TO_EXISTING_RUNAS_ROOT_UIDGID" == "1000 1000" ]; then
  if [ "$REUSED_REUSED_MOUNT_TO_NONEXIST_RUNAS_USERA_UIDGID" == "2000 2000" ]; then
    OWNERSHIP_OF_REUSED_VOL="First Assigned"
  elif  [ "$REUSED_REUSED_MOUNT_TO_NONEXIST_RUNAS_USERA_UIDGID" == "1000 1000" ]; then
    OWNERSHIP_OF_REUSED_VOL="Last Assigned"
  else 
    OWNERSHIP_OF_REUSED_VOL="Unknown"
  fi
else
  OWNERSHIP_OF_REUSED_VOL="Unknown"
fi

if [ "$RUNTIME" == "docker" ]; then
    DOCKERVER=`$RUNTIME version -f '{{.Client.Platform.Name}} : {{.Client.Version}}'`
elif [ "$RUNTIME" == "podman" ]; then
    DOCKERVER=`$RUNTIME version -f '{{.Client.Version}}'`
    DOCKERVER="Podman : $DOCKERVER"
else
    DOCKERVER='Unknown'
fi

echo "Client version|Honor ownership of existing mountpoints for fresh volumes|Honor ownership of existing mountpoints for reused volumes|Ownership of volumes mounted at non-existing mountpoints|Remembers ownership for reused vol mounted to non-existing mountpoint|Ownership for reused vol with non-existing mountpoint|"
echo "$DOCKERVER|$HONORS_EXISTING_MOUNT_OWNERSHIP_FOR_FRESH_VOLUMES|$HONORS_EXISTING_MOUNT_OWNERSHIP_FOR_REUSED_VOLUMES|$OWNERSHIP_OF_NONEXISTINGMOUNTS|$REMEMBERS_OWNERSHIP_REUSED_TO_NONEXIST|$OWNERSHIP_OF_REUSED_VOL"

if [ 1 == 1 ]; then
    echo first
    cat firstmountperms.txt
    echo second
    cat secondmountperms.txt
    echo third
    cat thirdmountperms.txt
    echo fourth
    cat fourthmountperms.txt
fi

rm *mountperms.txt

#Cleanup
$RUNTIME volume rm permtestvol1 >/dev/null 2>&1
$RUNTIME volume rm permtestvol2 >/dev/null 2>&1
$RUNTIME volume rm permtestvol3 >/dev/null 2>&1
$RUNTIME volume rm permtestvol4 >/dev/null 2>&1
$RUNTIME volume rm permtestvol5 >/dev/null 2>&1
$RUNTIME volume rm permtestvol6 >/dev/null 2>&1
$RUNTIME volume rm permtestvol7 >/dev/null 2>&1
$RUNTIME volume rm permtestvol8 >/dev/null 2>&1
$RUNTIME volume rm permtestvol9 >/dev/null 2>&1
$RUNTIME volume rm permtestvol10 >/dev/null 2>&1


