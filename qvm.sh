#!/bin/bash


VIRSH_BIN=/usr/bin/virsh
VERSION=0.1

# Start VMs
function startVMs {
    for vm in $("$VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
        virsh start $vm
    done
}


function stopVMs {
    for vm in $("$VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
        virsh shutdown $vm
    done
}

if [ -z $1 ]; then
cat <<EOF
start-vms.sh version ${VERSION}

Start and stop virtual maachines.
Syntax: ./start-vms.sh [start|stop]

EOF
exit
fi

if [ $1 == 'start' ]; then
    echo "Starting virtual machines..."
   startVMs
fi


if [ $1 == 'stop' ]; then
    echo "Shutting down virtual machines..."
    stopVMs
fi
