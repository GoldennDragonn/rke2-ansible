Role Name- "apt-sources-list"
================================

This role updates /etc/apt/sources.list

Variables
----------

Under "defaults/main.yml", the following varaiables are used to store the relevant sources list file name, according to the installed OS.

 - ubuntu_16_04_src_file: "ubuntu-sources-xenial.list"
 - ubuntu_18_04_src_file: "ubuntu-sources-bionic.list"
 - ubuntu_20_04_src_file: "ubuntu-sources-focal.list"
 - centos_docker_repo_src_file: "centos-docker-ce.repo"
 - centos_75_yum_src_file: "centos75yum.repo"

Usage
-----
Run main playbook, under: "tasks/main.yml"

