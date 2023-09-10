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
# set -e

# ASCII Art Header for our Script
echo "========================================"
echo "        RKE2 Cluster Deployment         "
echo "========================================"
echo ""

function step1() {
# Step 1: Install ansible-utils collection
print_step "Step 1: Installing Ansible Collections and updating packages..."
output1=$(ansible-galaxy collection install ansible-utils-2.10.3.tar.gz 2>&1)

if [[ "$output1" == *"was installed successfully"* ]] || [[ "$output1" == *"Nothing to do. All requested collections are already installed."* ]]; then
    echo -e "\033[0;32mColletion successfully ansible-utils-2.10.3 installed\033[0m"
fi

output2=$(ansible-galaxy collection install kubernetes-core-2.4.0.tar.gz 2>&1)

if [[ "$output2" == *"was installed successfully"* ]] || [[ "$output2" == *"Nothing to do. All requested collections are already installed."* ]]; then
    echo -e "\033[0;32mColletion successfully kubernetes-core-2.4.0 installed\033[0m"
fi

output3=$(ansible-galaxy collection install community-general-7.3.0.tar.gz 2>&1)

if [[ "$output2" == *"was installed successfully"* ]] || [[ "$output2" == *"Nothing to do. All requested collections are already installed."* ]]; then
    echo -e "\033[0;32mColletion successfully community-general-7.3.0 installed\033[0m"
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
echo -e "\033[0;32mInventory for cluster $FOLDER_NAME set up successfully.\033[0m"

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
# Step 3: Deploy the Cluster
print_step "Step 3: Deploying the Cluster"
#read -p "Set the user to deploy the cluster: " deploy_user
ansible-playbook rke2-deploy.yml -i inventory/$FOLDER_NAME/hosts.ini
}

function step4() {
# Step 4: Fetch and Setup kubeconfig
print_step "Step 4: Setting up kubeconfig from the Master node to Localhost"

ansible-playbook summary.yml -i inventory/$FOLDER_NAME/hosts.ini


}

function step5() {
    print_step "Uninstalling the Cluster"

    # # Prompt for necessary details
    # read -p "Enter the sudo user: " ANSIBLE_USER
    # read -sp "Enter the sudo password: " ANSIBLE_PASSWORD
    # echo  # Add a newline for cleaner output after the hidden password prompt

    #Prompt the user for folder name
    read -p "Enter the cluster inventory folder name: " FOLDER_NAME

    #Confirm deletion
    echo -e "\033[31mPlease confirm to delete the cluster $FOLDER_NAME. (yes/no): \033[0m " 
    read CONFIRMATION

    if [ "$CONFIRMATION" == "yes" ]; then
        ansible-playbook uninstall.yml -i inventory/$FOLDER_NAME/hosts.ini
        echo -e "\033[0;32mRKE2Cluster $FOLDER_NAME was successfully deleted\033[0m"
    else 
        print_with_color "1;37" "Exiting. $FOLDER_NAME was not deleted."
        exit 0
    fi 

    # Run the uninstall command on all nodes in the inventory
    # ansible all -i inventory/$FOLDER_NAME/hosts.ini -u $ANSIBLE_USER --become --ask-become-pass -m shell -a "/usr/local/bin/rke2-uninstall.sh"

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
elif [[ $deployment_choice -eq 2 ]]; then
    # Continuation, ask the user from which step to start
    # read -p "Choose the step to start from (1-4): " start_step
    print_with_color "1;37" "Choose the step to start from:"
    echo "1. Installing Ansible Collection"
    echo "2. Generating inventory"
    echo "3. Deploying the Cluster"
    echo "4. Setting up kubeconfig from the Master node to Localhost"
    read -p "(1-4): " start_step
    case $start_step in
        1)
            echo "Starting from Step 1: Installing ansible-utils collection..."
            step1
            step2
            step3
            step4
            ;;
        2)
            echo "Starting from Step 2: Generating inventory..."
            step2
            step3
            step4
            ;;
        3)
            echo "Starting from Step 3: Deploying the Cluster"
            print_with_color "1;37" "Enter the name of your cluster inventory folder:"
            read FOLDER_NAME
            step3 "$FOLDER_NAME"
            ;;
        4)
            echo "Starting from Step 4: Setting up kubeconfig from the first master node"
            print_with_color "1;37" "Enter the name of your cluster inventory folder:"
            read FOLDER_NAME
            step4 "$FOLDER_NAME"
            ;;
        *)
            echo "Invalid step choice. Exiting."
            exit 1
            ;;
    esac
elif [[ $deployment_choice -eq 3 ]]; then
    # Uninstalling the cluster
    step5
else
    echo "Invalid deployment choice. Exiting."
    exit 1
fi

# Completion Message
print_step "Script Completed! Thank you for using RKE2 Cluster Deployment."
