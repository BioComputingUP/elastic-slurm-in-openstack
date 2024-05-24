# Slurm cluster in OpenStack cloud
These Ansible playbooks create and manage a dynamically allocated (elastic) Slurm cluster in an OpenStack cloud.
The cluster is based on CentOS 8 and [OpenHPC 2.x](https://openhpc.community/downloads/). Slurm configurations are based on the work contained in (https://github.com/XSEDE/CRI_Jetstream_Cluster).
This repo is based on the project [slurm-cluster-in-openstack](https://github.com/CornellCAC/slurm-cluster-in-openstack)
adapted for use with [CloudVeneto](https://cloudveneto.ict.unipd.it/) OpenStack cloud.

## Systems Requirements
1. Access to an OpenStack cloud such as [Red Cloud](https://redcloud.cac.cornell.edu) at [Cornell University Center for Advanced Computing](https://www.cac.cornell.edu)
1. [`openrc` file](https://www.cac.cornell.edu/wiki/index.php?title=OpenStack_CLI#Download_OpenStack_RC_File) containing credentials for accessing OpenStack cloud.
1. A computer with python 3.6 or later installed.
1. Clone this repo to your computer.

## Prerequisites
### Install Ansible
Run the `install_ansible.sh` command:
```bash
./install_ansible.sh
```
## Deploy Slurm Cluster
### Enable a floating IP for the headnode
Create a floating IP and ask to open port 22 to it. Don't associate it to a VM.

### Download rocky-8.8 image
```bash
wget https://dl.rockylinux.org/vault/rocky/8.8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2
# no need to upload it to OpenStack, Ansible will do it
# openstack image create --disk-format qcow2 --container-format bare --file Rocky-8-GenericCloud-Base.latest.x86_64.qcow2 rocky-8.8
```
### Configure cluster
Adjust `vars/main.yml` and use `cloudveneto.medium` flavor for head node and compute
imaging instance and `cloudveneto.xlarge` for compute node.

Adjust `clouds.yaml` with OpenStack credentials.

### Deployment
Deployment is done in four steps:
1. Create the head node
2. Provision the head node
3. Create and provision the compute node
4. Create the compute node image

#### Create the head node
```bash
source ansible/bin/activate
source ELIXIRxNextGenIT-openrc.sh
ansible-playbook create_headnode.yml
```

#### Provision the head node
```bash
source ansible/bin/activate
source ELIXIRxNextGenIT-openrc.sh
ansible-playbook provision_headnode.yml
```

#### Create and provision the compute node
```bash
source ansible/bin/activate
source ELIXIRxNextGenIT-openrc.sh
ansible-playbook create_compute_node.yml
```

#### Create compute node image
```bash
source ansible/bin/activate
source ELIXIRxNextGenIT-openrc.sh
ansible-playbook create_compute_image.yml
```

#### All-in-one deployment
```bash
source ansible/bin/activate
source ELIXIRxNextGenIT-openrc.sh
time ( \
ansible-playbook create_headnode.yml && \
ansible-playbook provision_headnode.yml && \
ansible-playbook create_compute_node.yml && \
ansible-playbook create_compute_image.yml && \
echo "Deployment completed" || echo "Deployment failed" )
```
or fancy with notifications:
```bash
source ansible/bin/activate
source ELIXIRxNextGenIT-openrc.sh
/bin/time -f "\n### overall time: \n### wall clock: %E" /bin/bash -c '\
/bin/time -f "\n### timing \"%C ...\"\n### wall clock: %E" ansible-playbook create_headnode.yml && \
/bin/time -f "\n### timing \"%C ...\"\n### wall clock: %E" ansible-playbook provision_headnode.yml && \
/bin/time -f "\n### timing \"%C ...\"\n### wall clock: %E" ansible-playbook create_compute_node.yml && \
/bin/time -f "\n### timing \"%C ...\"\n### wall clock: %E" ansible-playbook create_compute_image.yml && \
echo "Deployment completed" | tee /dev/tty | notify-send -t 0 "$(</dev/stdin)" || \
echo "Deployment failed" | tee /dev/tty | notify-send -t 0 "$(</dev/stdin)"'
```

### Cleanup
Delete all cloud resources with:
```bash
source ansible/bin/activate
source ELIXIRxNextGenIT-openrc.sh
ansible-playbook destroy_cluster.yml
```

