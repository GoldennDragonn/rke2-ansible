
##################################################
#                                                #
#           RKE2 Cluster Deployment              #
#                                                #
##################################################


## Overview
This script automates the deployment of an RKE2 Kubernetes cluster. By running the script, you'll be able to set up the cluster with minimal manual intervention.

## Prerequisites
- **Bash** must be installed and configured on your system.
- **Ansible version 2.12 and higher** must be installed and configured on your system.
- The script assumes that you have necessary permissions to execute and make changes on the system.
- Make sure to backup any important data or configurations before proceeding.
- Prepared Virtual Machines (VMs) with either Linux or Windows operating systems.
  - **RAM**: 4GB minimum (8GB recommended)
  - **CPU**: 2 cores minimum (4 cores recommended)
- **Image Prerequisites**:
  1. Set up a private registry and configure it in `/extraconfigs/manifest/registries.yaml`.
  2. Upload the following image tarballs to the `/tarball_install` folder (create if doesn't exists):
     - `rke2-images.linux-amd64.tar.gz`
     - `rke2-images.linux-amg64.tar.zst`
     - `sha256sum-amd64.txt`
  3. Upload `rke2.linux-amd64.tar.gz` to the `/tarball_install` (create if doesn't exists)
  4. Manually setting up Inventory: 
   4.1. Navigate to /inventory folder and copy `yb_cluster` folder with your cluster name
   4.2  Set up users and password in /inventory/(your_cluster_name)/group_vars/all.yml
## Steps to Deploy RKE2 Cluster

### Step 1: Installing ansible-utils collection
The script will automatically install the `ansible-utils` collection. This is essential for subsequent steps in the setup process.

### Step 2: Generating inventory
An inventory will be generated which is crucial for Ansible playbooks. Ensure that the generated inventory matches your infrastructure requirements.

### Step 3: Reviewing Configuration Files
Before proceeding further, it's essential to review the configuration files. Ensure they align with your desired cluster setup.

### Step 4: Creating non-root user and copying SSH keys
For security reasons, the script will create a non-root user on the target nodes and copy the SSH keys. This allows for secure communication between nodes.

### Step 5: Deploying the Cluster
The main deployment step – the RKE2 cluster will be set up during this phase.

### Step 6: Setting up kubeconfig from the first master node
To manage the Kubernetes cluster, `kubeconfig` will be set up from the first master node. This ensures you have the necessary credentials and context to manage the deployed cluster.

### Step 7: Verifying Cluster Setup
The script will run some checks to verify that the cluster has been set up correctly.

### Completion
Once all steps have been completed, you'll receive a confirmation message: "Script Completed! Thank you for using RKE2 Cluster Deployment."

## How to Run the Script
1. Navigate to the directory containing the `rke2-setup.sh` script.
2. Make the script executable:
   ```bash
   chmod +x rke2-setup.sh
   ```
3. Run the script:
   ```bash
   ./rke2-setup.sh
   ```

## Troubleshooting
If you encounter any issues while running the script:
- Ensure that you have the necessary permissions.
- Check the script's output for any specific error messages and act accordingly.
- Review the configuration files if prompted by the script to ensure they are correct.

## Conclusion
By following this README, you should be able to deploy an RKE2 Kubernetes cluster smoothly. Ensure to always review any auto-generated configuration files and adjust them according to your needs.
