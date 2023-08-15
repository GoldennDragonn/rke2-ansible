#!/bin/bash

# Ask the user if they already have an inventory file
echo "Do you have an inventory file in /inventory/(your_cluster_name)/hosts.ini? (yes/no)"
read has_inventory

if [[ "$has_inventory" == "yes" ]]; then
    # Ask for the cluster name folder if the inventory file exists
    echo "Enter the name of your cluster inventory folder:"
    read folder_name
    echo "Using existing inventory file in /inventory/$folder_name/hosts.ini."
else
    # Ask the user for the name of the cluster inventory folder
    echo "Enter the name for your new cluster inventory folder:"
    read folder_name

    # Copy the reference folder to the user-specified folder name
    cp -R inventory/yb-cluster inventory/$folder_name

    # Initialize the hosts.ini file
    > hosts.ini

    # Collect Master nodes details
    echo "Enter the number of Master Nodes:"
    read num_masters

    echo -e "[rke2_servers]" >> hosts.ini
    for ((i=1; i<=$num_masters; i++)); do
        echo "Enter the IP of Master Node ${i}:"
        read master_ip
        echo "$master_ip node_labels='[\"extraLabel0=true\"]' node_ip=\"$master_ip\"" >> hosts.ini
    done

    # Collect Worker nodes details
    echo "Enter the number of Worker Nodes:"
    read num_workers

    echo -e "\n[rke2_agents]" >> hosts.ini
    for ((i=1; i<=$num_workers; i++)); do
        echo "Enter the IP of Worker Node ${i}:"
        read worker_ip
        echo "$worker_ip node_labels='[\"extraLabel0=true\"]' node_ip=\"$worker_ip\"" >> hosts.ini
    done

    # Add the rke2 cluster children section
    echo -e "\n[rke2_cluster:children]\nrke2_servers\nrke2_agents" >> hosts.ini

    # Prompt for RKE2 version
    echo "Specify the RKE2 full version (e.g., v1.26.6+rke2r1):"
    read rke2_version
    echo -e "\n[all:vars]\ninstall_rke2_version = $rke2_version" >> hosts.ini

    # Copy the hosts.ini to the user-specified folder
    cp hosts.ini inventory/$folder_name/
fi

export FOLDER_NAME=$folder_name
export HOSTS=hosts.ini
