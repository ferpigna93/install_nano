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

get_name() {
    local idx=$1
    if [ "$idx" -eq 0 ]; then
        echo "Nanotecnologia"
    else
        printf "nano%d" "$idx"
    fi
}

print_menu() {
    echo
    echo "========================================="
    echo "       Nanotecnologia SSH Menu"
    echo "========================================="
    # Print sorted indices (put 99 at the end)
    local sorted_indices
    sorted_indices=$(for k in "${!SSH_HOSTS[@]}"; do echo "$k"; done | sort -n)
    for idx in $sorted_indices; do
        printf "  [%2d]  %s  (%s)\n" "$idx" "$(get_name "$idx")" "${SSH_HOSTS[$idx]}"
    done
    echo "========================================="
    echo "   [q]  Quit"
    echo "========================================="
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

while true; do
    print_menu
    read -rp "Enter PC number: " choice

    [[ "$choice" == "q" || "$choice" == "Q" ]] && { echo "Bye!"; exit 0; }

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
