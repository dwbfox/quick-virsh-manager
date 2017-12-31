#!/bin/bash
###############################################################################
#
#   Quick Virsh Manager v0.5.1
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

# Remove before flight
# set -e 
# set -u
# set -o pipefail
# set -x



show_usage() {
cat <<EOF
usage: qvm [options] [command]

Examples:
    qvm backup -d centos-vm-01 -b /tmp/mydomainxmls     # Create a directory and backup the domain XML at the specified location
    qvm list                                            # List all running and stopped domains, equivalent to "virsh list --all"
    qvm reboot -d centos-vm-01                          # Gracefully reboots the specified domain

List of commands:
    backup                          backup domain XMLs, by default in the current directory. Can be combined 
                                    with -b and -d to specify directories and specific domains to backup
    list                            List all domains, analogous to running "virsh list --all". 
                                    Can be combined with -d to list a specific domain
    reboot                          Gracefully reboots all domains. Can be combined with -d to specify a domain to reboot
    start                           Starts all domains. Can be combined with -d to specify a domain to start

Command options:
    -b [directory]       Specify a directory
    -d [domain]          Specify a domain
    -h                   Display this help
    -o [file]            Output verbose logging to a specified file
    -i [path]            Virsh executable path, by default /usr/bin/virsh
    -v                   Enable verbose command outputs

Quick Virsh Manager v0.5.1

EOF
    tput init
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

yes_or_exit() {
    read -r  response
    if [[ ! "$response" = "y" || ! "$response" = "Y" ]]; then
        echo_error "Exiting...$response"
        exit 1
    fi
}

stop_vm() {
    for vm in $("$FLAG_VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 7); do
        $FLAG_VIRSH_BIN shutdown "$vm"
    done
}

backup_domain() {

    if [[ ! -z $FLAG_DOMAIN ]]; then
        echo_success "Backing up ${FLAG_DOMAIN} to ${FLAG_DIRECTORY}"
        if [[ ! -z $FLAG_DIRECTORY && -d $FLAG_DIRECTORY ]]; then
            # Check if there are existing domain backups at this location
            if [[ -f "${FLAG_DIRECTORY}/${FLAG_DOMAIN}.xml" ]]; then
                echo_error "A file exists under "${FLAG_DIRECTORY}/${FLAG_DOMAIN}.xml". Do you want to continue and overwrite this file? [Y/N]"
                yes_or_exit
            fi
            $FLAG_VIRSH_BIN dumpxml "$FLAG_DOMAIN" > "$FLAG_DIRECTORY/$FLAG_DOMAIN.xml"
        else
            $FLAG_VIRSH_BIN dumpxml "$FLAG_DOMAIN" > "./$FLAG_DOMAIN.xml"
        fi
    else
       for vm in $("$FLAG_VIRSH_BIN" list --all | sed 1,2d | cut -d' ' -f 6,7); do
            echo_verbose "Backing up VM"
            if [[ ! -z $FLAG_DIRECTORY && -d $FLAG_DIRECTORY ]]; then
                # Check if there are existing domain backups at this location
                if [[ -f "${FLAG_DIRECTORY}/${FLAG_DOMAIN}.xml" ]]; then
                    echo_error "A file exists under "${FLAG_DIRECTORY}/${FLAG_DOMAIN}.xml". Do you want to continue and overwrite this file? [Y/N]"
                    yes_or_exit
                fi
                $FLAG_VIRSH_BIN dumpxml "$vm" > "$FLAG_DIRECTORY/$vm.xml"
            else
                $FLAG_VIRSH_BIN dumpxml "$vm" > "./$vm.xml"
            fi
       done;
    fi
}

list_vm() {
    echo_verbose "${FUNCNAME[0]}() flag domain value: $FLAG_DOMAIN"
    if [[ ! -z "$FLAG_DOMAIN" ]]; then
        $FLAG_VIRSH_BIN list --all | grep "$FLAG_DOMAIN"
    else
        $FLAG_VIRSH_BIN list --all
    fi
}

echo_verbose() {
    log="[$(date +'%Y-%m-%d %H:%m:%S')] -> $1"
    if [[ ! "$FLAG_VERBOSE" -eq 0 ]]; then
        echo "$log"
    fi
    if [[ ! -z "$FLAG_LOG_LOCATION" ]]; then
        echo "$log" >> "$FLAG_LOG_LOCATION"
    fi
}


echo_error() {
    tput setaf 1; printf "$1\n"; tput init
}


echo_success() {
    tput setaf 2; printf "$1\n\n"; tput init
}

FLAG_VIRSH_BIN=/usr/bin/virsh
FLAG_LOG_LOCATION=""
FLAG_DOMAIN=""
FLAG_DIRECTORY=""
FLAG_VERBOSE=0


# Parse incoming options
while getopts "i:vd:b:ho:" opt; do
    case "${opt}" in
        b )
            FLAG_DIRECTORY=$OPTARG
            echo_verbose "Directory set to ${FLAG_DIRECTORY}"
            ;;
        d )
            FLAG_DOMAIN=$OPTARG
            echo_verbose "Domain set to ${FLAG_DOMAIN}"
            ;;
        h )
            show_usage
            ;;
        i ) 
            FLAG_VIRSH_BIN=$OPTARG
            echo_verbose "Virsh executable path changed to ${FLAG_VIRSH_BIN}"
            ;;
        o )
            FLAG_LOG_LOCATION=$OPTARG
            ;;
        v )
            FLAG_VERBOSE=1
            echo_verbose "Verbose mode enabled"
            ;;
        \?)
            echo_error "Invalid option specified"
            show_usage
            ;;
    esac
done
shift "$((OPTIND-1))"

case "${1}" in
    backup )
        echo_verbose "Backup command specified"
        backup_domain
        ;;
    list )
        echo_verbose "List command specified"
        list_vm
        ;;
    reboot )
        echo_verbose "Reboot command specified"
        ;;
    start ) 
        echo_verbose "Start command specified"
        ;;
    * )
        echo_error "Invalid command specified: $1"
        show_usage
        exit 1
        ;;
esac

