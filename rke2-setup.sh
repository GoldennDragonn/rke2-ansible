#!/bin/bash

# Helper function to print with colors
function print_with_color() {
    local color_code="$1"
    local message="$2"
    echo -e "\033[${color_code}m${message}\033[0m"
}

# Improved function to print steps with yellow color
function print_step() {
    print_with_color "33" "----------------------------------------"
    print_with_color "33" "$1"
    print_with_color "33" "----------------------------------------"
    echo ""
}

# Exit on any error
set -e

# ASCII Art Header for our Script
echo "========================================"
echo "        RKE2 Cluster Deployment         "
echo "========================================"
echo ""

function step1() {
# Step 1: Install ansible-utils collection
print_step "Step 1: Installing ansible-utils collection and updating packages..."
output=$(ansible-galaxy collection install ansible-utils-2.10.3.tar.gz 2>&1)

if [[ "$output" == *"was installed successfully"* ]] || [[ "$output" == *"Nothing to do. All requested collections are already installed."* ]]; then
    echo -e "\033[0;32mColletion successfully installed\033[0m"
fi

apt_output=$(sudo apt update 2>&1)

    if [[ "$apt_output" == *"All packages are up to date"* ]]; then
        echo -e "\033[0;32mAll packages are up to date\033[0m"
    else
        echo -e "$apt_output"
    fi
}

function step2() {
# Step 2: Generate Inventory
print_step "Step 2: Generating inventory..."
. rke2-hostsini-set.sh
echo -e "\033[0;32mInventory for cluster $FOLDER_NAME generated successfully.\033[0m"}

# Prompt user to review configuration files
print_step "Please Review Configuration Files"
echo -e "\033[1;37mGo to /inventory/$FOLDER_NAME/group_vars\033[0m"
echo -e "\033[1;37mReview and modify rke2_server and rke2_agents config files if needed.\033[0m"
read -p "Enter 'yes' to continue deployment or 'quit' to stop: " user_input

# Check user's input and act accordingly
if [[ $user_input == "quit" ]]; then
    echo "Stopped script deployment.."
    exit 0
elif [[ $user_input != "yes" ]]; then
    echo "Invalid input. Exiting script."
    exit 1
fi

}

function step3() {
# Step 3: Create non-root user and copy SSH keys
local FOLDER_NAME="$1"
print_step "Step 3: Copying SSH keys to all hosts..."
ansible-playbook set-user-ssh.yml -i inventory/$FOLDER_NAME/hosts.ini
}

function step4() {
# Step 4: Deploy the Cluster
local FOLDER_NAME="$1"
print_step "Step 4: Deploying the Cluster"
#read -p "Set the user to deploy the cluster: " deploy_user
ansible-playbook rke2-deploy.yml -i inventory/$FOLDER_NAME/hosts.ini
}

function step5() {
# Step 5: Fetch and Setup kubeconfig
# Step 5: Fetch and Setup kubeconfig
print_step "Step 5: Setting up kubeconfig from the main master node"

read -p "Enter the Ansible user: " ANSIBLE_USER
read -p "Enter the IP of the main master node: " MASTER_IP
read -s -p "Enter the SSH password: " SSH_PASS

sshpass -p "$SSH_PASS" ssh $ANSIBLE_USER@$MASTER_IP "sudo -S cat /etc/rancher/rke2/rke2.yaml" | sed "s/127.0.0.1/$MASTER_IP/g" > temp_rke2.yaml

mv temp_rke2.yaml ~/.kube/config_rke2

cp ~/.kube/config ~/.kube/config-backup

# # Merge the fetched configuration with the existing ~/.kube/config
echo "Merging the fetched configuration with ~/.kube/config..."
# KUBECONFIG=~/.kube/config:config_rke2 kubectl config view --flatten > /tmp/config

export KUBECONFIG=~/.kube/config:~/.kube/config_rke2

kubectl config view --flatten > all-in-one-kubeconfig.yaml

# # Replace the old config with the new merged config
mv all-in-one-kubeconfig.yaml ~/.kube/config

# #Set ~/.kube/config permissions
chmod go-r ~/.kube/config 


# Remove the temporary rke2.yaml
#rm temp_rke2.yaml


# Switch to the new context
kubectl config use-context default

# Verifying the cluster setup
print_step "Verifying Cluster Setup"

# First, check if we can connect to the cluster and authenticate
if kubectl get nodes &> /dev/null; then
    # Check if any node is NOT in the "Ready" state
    if kubectl get nodes --no-headers | grep -vq "Ready"; then
        print_with_color "31" "Warning: One or more nodes are not in the Ready state."
    else
        print_with_color "32" "Your RKE2 cluster is now up and running."
    fi
else
    print_with_color "31" "Error: Unable to connect to the cluster or authenticate."
fi

}

function step6() {
    print_step "Step 6: Uninstalling the Cluster"

    # Prompt for necessary details
    read -p "Enter the sudo user: " ANSIBLE_USER
    read -sp "Enter the sudo password: " ANSIBLE_PASSWORD
    echo  # Add a newline for cleaner output after the hidden password prompt
    read -p "Enter the cluster inventory folder name: " FOLDER_NAME

    # Run the uninstall command on all nodes in the inventory
    ansible all -i inventory/$FOLDER_NAME/hosts.ini -u $ANSIBLE_USER --become --ask-become-pass -m shell -a "/usr/local/bin/rke2-uninstall.sh"
}


# Prompt for new deployment or continuation
print_with_color "1;37" "Is this a new deployment or continue from a previous run?"
read -p "(Enter 1 for new, 2 for continue, 3 for uninstall): " deployment_choice

if [[ $deployment_choice -eq 1 ]]; then
    # New deployment, execute all steps in sequence
    step1
    step2
    step3
    step4
    step5
elif [[ $deployment_choice -eq 2 ]]; then
    # Continuation, ask the user from which step to start
    # read -p "Choose the step to start from (1-5): " start_step
    print_with_color "1;37" "Choose the step to start from:"
    echo "1. Installing ansible-utils collection"
    echo "2. Generating inventory"
    echo "3. Copying SSH keys for sudo privileged user"
    echo "4. Deploying the Cluster"
    echo "5. Setting up kubeconfig from the first master node"
    read -p "(1-5): " start_step
    case $start_step in
        1)
            echo "Starting from Step 1: Installing ansible-utils collection..."
            step1
            step2
            step3
            step4
            step5
            ;;
        2)
            echo "Starting from Step 2: Generating inventory..."
            step2
            step3
            step4
            step5
            ;;
        3)
            echo "Starting from Step 3: Creating non-root user and copying SSH keys..."
            print_with_color "97" "Enter the cluster inventory folder name: "
            read FOLDER_NAME
            step3 "$FOLDER_NAME"
            step4 "$FOLDER_NAME"
            step5
            ;;
        4)
            echo "Starting from Step 4: Deploying the Cluster"
            print_with_color "97" "Enter the cluster inventory folder name: "
            read FOLDER_NAME
            step4 "$FOLDER_NAME"
            step5
            ;;
        5)
            echo "Starting from Step 5: Setting up kubeconfig from the first master node"
            step5
            ;;
        *)
            echo "Invalid step choice. Exiting."
            exit 1
            ;;
    esac
elif [[ $deployment_choice -eq 3 ]]; then
    # Uninstalling the cluster
    step6
else
    echo "Invalid deployment choice. Exiting."
    exit 1
fi

# Completion Message
print_step "Script Completed! Thank you for using RKE2 Cluster Deployment."
