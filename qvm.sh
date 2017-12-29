#!/bin/bash
###############################################################################
#
#   Quick Virsh Manager v0.5.1
#   Dagmawi Biru dbiru@cisco.com
#
#   MIT License
#   
#   Copyright (c) 2017
#   
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#   
#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.
#   
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.
#   
###############################################################################




show_usage() {
cat <<EOF
usage: qvm [options]

Examples:
    qvm -d centos-vm-01 -b /tmp/mydomainxmls     # Create a directory and backup the domain XML at the specified location
    qvm -l                                       # List all running and stopped domains, equivalent to "virsh list --all"
    qvm -r -d centos-vm-01                       # Gracefully reboots the specified domain

Command options:
    -b [directory]       Backup all domain XMLs into the specified directory, can be combined with -d to specify a specific domain XML to backup
    -d [domain]          The name of the domain to run a command on
    -e                   Destroy/stop all running domains, can be combined with -d to specify a specific domain
    -l                   List all domains, including ones that are shut down      
    -h                   Display this help
    -i [path]            Virsh executable path, by default /usr/bin/virsh
    -r                   Gracefully reboot (soft reboot) all running domains, can be combined with -d to specify a specific domain
    -s                   Start all domains, can be combined with -d to specify a specific domain
    -v                   Enable verbose command outputs

Quick Virsh Manager v0.5.1

EOF
    exit 0
}


# Start VMs
start_vm() {
    if [[ ! -z $FLAG_DOMAIN ]]; then
        echo_verbose "${FUNCNAME[0]}() called with specific domain ($FLAG_DOMAIN), starting VM"
        $FLAG_VIRSH_BIN start "$FLAG_DOMAIN"
    else
        echo_verbose "${FUNCNAME[0]}() called with no domain, starting ALL VMs"
        for vm in $("$FLAG_VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
            $FLAG_VIRSH_BIN start "$vm"
        done
    fi
}

stop_vm() {
    for vm in $("$FLAG_VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
        $FLAG_VIRSH_BIN shutdown "$vm"
    done
}

backup_domain() {
   for vm in $("$FLAG_VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 6,7); do
        echo_verbose "Backing up $vm to $1/$vm.xml"
        $FLAG_VIRSH_BIN dumpxml "$vm" > "$1/$vm.xml"
   done;
}

list_vm() {
    echo_verbose "${FUNCNAME[0]}() flag domain value: $FLAG_DOMAIN"
    if [[ ! -z "$FLAG_DOMAIN" ]]; then
        $FLAG_VIRSH_BIN list --all | grep $FLAG_DOMAIN
        if [[ ! "$?" -eq 0 ]]; then
            echo "Lookup failed. Check if \"$FLAG_DOMAIN\" exists."
        fi
    else
        $FLAG_VIRSH_BIN list --all
    fi
}

echo_verbose() {
    log="[$(date +'%Y-%m-%d %H:%m:%S')] -> $1"
    if [[ ! "$FLAG_VERBOSE" -eq 0 ]]; then
        echo $log
    fi
    if [[ ! -z "$FLAG_LOG_LOCATION" ]]; then
        echo "$log" >> "$FLAG_LOG_LOCATION"
    fi
}


FLAG_VIRSH_BIN=/usr/bin/virsh
FLAG_LOG_LOCATION=""
FLAG_DOMAIN=""
FLAG_DIRECTORY=""
FLAG_VERBOSE=0
while getopts "o:b:d:vesrlh" opt; do
    case $opt in
        b )
            echo_verbose "Directory specified: $OPTARG"
            FLAG_DIRECTORY=$OPTARG
            ;;
        d )
            echo_verbose "Domain specified: $OPTARG"
            FLAG_DOMAIN=$OPTARG
            ;;            
        h )
            show_usage
            ;;
        l )
            echo_verbose "-l, listing domains"
            list_vm
            ;;
        o )
            echo_verbose "Logging location: $OPTARG"
            FLAG_LOG_LOCATION=$OPTARG
            ;;
        s ) 
            echo_verbose "Starting domain..."
            start_vm
            ;;
        v )
            FLAG_VERBOSE=1
            echo_verbose "Verbose enabled"
            ;;

        \?)
            echo_verbose "Unknown argument, calling show_usage()"
            show_usage
            ;;
    esac
done

