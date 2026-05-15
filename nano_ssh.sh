#!/bin/bash

# SSH connection menu for Nanotecnologia lab PCs

declare -A SSH_HOSTS=(
    [0]="164.73.160.239"
    [2]="root@164.73.160.121"
    [3]="root@164.73.160.147"
    [4]="root@164.73.160.205"
    [5]="root@164.73.160.245"
    [6]="root@164.73.160.206"
    [7]="root@164.73.160.204"
    [8]="root@164.73.160.218"
    [9]="root@164.73.160.251"
    [10]="root@164.73.160.64"
    [11]="root@164.73.160.36"
    [12]="root@164.73.160.46"
    [13]="root@164.73.163.88"
    [14]="root@164.73.163.89"
    [15]="root@164.73.163.103"
    [16]="root@164.73.163.116"
    [17]="root@164.73.163.217"
    [18]="root@164.73.163.211"
    [19]="root@164.73.163.208"
    [21]="root@164.73.160.244"
    [22]="root@164.73.163.204"
    [23]="root@164.73.163.115"
    [24]="root@164.73.163.117"
    [25]="root@164.73.163.206"
    [99]="root@164.73.163.212"
)

declare -A HOST_STATUS

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

get_name() {
    local idx=$1
    if [ "$idx" -eq 0 ]; then
        echo "Nanotecnologia"
    else
        printf "nano%d" "$idx"
    fi
}

get_ip() {
    local host=$1
    echo "${host##*@}"
}

# Try TCP connection to port 22; works without nc via bash /dev/tcp fallback
check_port() {
    local ip=$1
    if command -v nc &>/dev/null; then
        nc -z -w 2 "$ip" 22 2>/dev/null
    else
        timeout 2 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null
    fi
}

check_all_hosts() {
    echo "Checking host status..."
    local tmpdir
    tmpdir=$(mktemp -d)

    for idx in "${!SSH_HOSTS[@]}"; do
        local ip
        ip=$(get_ip "${SSH_HOSTS[$idx]}")
        (
            if check_port "$ip"; then
                echo "ACTIVE" > "$tmpdir/$idx"
            else
                echo "INACTIVE" > "$tmpdir/$idx"
            fi
        ) &
    done

    wait

    for idx in "${!SSH_HOSTS[@]}"; do
        HOST_STATUS[$idx]=$(cat "$tmpdir/$idx" 2>/dev/null || echo "UNKNOWN")
    done

    rm -rf "$tmpdir"
}

print_menu() {
    echo
    echo "====================================================="
    echo "           Nanotecnologia SSH Menu"
    echo "====================================================="
    local sorted_indices
    sorted_indices=$(for k in "${!SSH_HOSTS[@]}"; do echo "$k"; done | sort -n)
    for idx in $sorted_indices; do
        local status="${HOST_STATUS[$idx]:-UNKNOWN}"
        if [ "$status" = "ACTIVE" ]; then
            status_display="${GREEN}ACTIVE${NC}"
        else
            status_display="${RED}INACTIVE${NC}"
        fi
        printf "  [%2d]  %-15s  %-21s  %b\n" \
            "$idx" "$(get_name "$idx")" "$(get_ip "${SSH_HOSTS[$idx]}")" "$status_display"
    done
    echo "====================================================="
    echo "   [r]  Refresh status"
    echo "   [q]  Quit"
    echo "====================================================="
    echo
}

connect() {
    local idx=$1
    local host="${SSH_HOSTS[$idx]}"
    local name
    name=$(get_name "$idx")

    if [ "$idx" -eq 0 ]; then
        read -rp "Username: " ssh_user
        echo "Connecting to $name ($ssh_user@$host)..."
        ssh -o PubkeyAcceptedKeyTypes=+ssh-rsa -X "$ssh_user@$host"
    else
        echo "Connecting to $name ($host)..."
        ssh -o PubkeyAuthentication=no -X "$host"
    fi
}

check_all_hosts

while true; do
    print_menu
    read -rp "Enter PC number: " choice

    [[ "$choice" == "q" || "$choice" == "Q" ]] && { echo "Bye!"; exit 0; }
    [[ "$choice" == "r" || "$choice" == "R" ]] && { check_all_hosts; continue; }

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number."
        continue
    fi

    choice=$((10#$choice))  # force base-10

    if [[ -z "${SSH_HOSTS[$choice]+_}" ]]; then
        echo "No PC found for index $choice."
        continue
    fi

    connect "$choice"
done
