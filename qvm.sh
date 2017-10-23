#!/bin/bash

VIRSH_BIN=/usr/bin/virsh

# Start VMs
function startVMs {
    for vm in $("$VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
        $VIRSH_BIN start "$vm"
    done
}

function stopVMs {
    for vm in $("$VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
        $VIRSH_BIN shutdown "$vm"
    done
}

function backupXMLs {
   for vm in $("$VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
        echo "Backing up $vm to $1/$vm.xml"
        $VIRSH_BIN dumpxml "$vm" > "$1/$vm.xml"
   done;
}

function listVMs {
    $VIRSH_BIN "list --all"
}

if [ -z "$1" ]; then
    cat <<EOF
      start-vms.sh version 0.1

      Start and stop virtual maachines.
      Syntax: ./start-vms.sh [start|stop|backup|...]

      start:    Starts all VMs

      stop:     Stops all VMs

      list:     List all VMs

      backup:   Backs up all VM domain XMLs to the
                specified directory. Format:
                backup <path>
EOF
    exit 0

fi

if [[ $1 == 'start' ]]; then
    echo "Starting virtual machines..."
   startVMs
   sleep 1
   listVMs
fi

if [[ $1 == 'stop' ]]; then
    echo "Shutting down virtual machines..."
    stopVMs
    sleep 1
    listVMs
fi

if [[ $1 == 'list' ]]; then
    echo "Listing virtual machines..."
    listVMs
fi

if [[ $1 == 'backup' ]]; then
    if [[ ! -d $2 ]]; then
        echo "Specified backup directory was not found: ${2}"
        exit 1
    fi
    echo "Backing up virtual machine domain XML..."
    echo "Backup location: ${2}"
    backupXMLs $2
fi
