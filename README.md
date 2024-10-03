# Slurm cluster in OpenStack cloud
These Ansible playbooks create and manage a dynamically allocated (elastic) Slurm cluster in an OpenStack cloud.
The cluster is based on CentOS 8 (Rocky 8) and [OpenHPC 2.x](https://openhpc.community/downloads/). Slurm configurations are based on the work contained 
in [Jetstream_Cluster](https://github.com/XSEDE/CRI_Jetstream_Cluster).
This repo is based on the project [slurm-cluster-in-openstack](https://github.com/CornellCAC/slurm-cluster-in-openstack)
adapted for use with [CloudVeneto](https://cloudveneto.ict.unipd.it/) OpenStack cloud.

## Prerequisites
### Install Ansible
Run the `install_ansible.sh` command:
```bash
./install_ansible.sh
```
## Deploy Slurm Cluster
### Enable a floating IP for the headnode
Create a floating IP and ask to open port 22 to it. Don't associate it to a VM.

### Download latest Rocky Linux 8 image
```bash
wget https://dl.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2
# no need to upload it to OpenStack, Ansible will do it
# openstack image create --disk-format qcow2 --container-format bare --file Rocky-8-GenericCloud-Base.latest.x86_64.qcow2 rocky-8
```
### Configure cluster
Copy `vars/main.yml.example` to `vars/main.yml` and adjust to your needs.

Copy `clouds.yaml.example` to `clouds.yaml` and adjust with OpenStack credentials.

### Deployment
Deployment is done in four steps:
1. Create the head node
2. Provision the head node
3. Create and provision the compute node
4. Create the compute node image

#### Create the head node
```bash
ansible-playbook create_headnode.yml
```

#### Provision the head node
```bash
ansible-playbook provision_headnode.yml
```

#### Create and provision the compute node
```bash
ansible-playbook create_compute_node.yml
```

#### Create compute node image
```bash
ansible-playbook create_compute_image.yml
```

#### All-in-one deployment
```bash
time ( \
ansible-playbook create_headnode.yml && \
ansible-playbook provision_headnode.yml && \
ansible-playbook create_compute_node.yml && \
ansible-playbook create_compute_image.yml && \
echo "Deployment completed" || echo "Deployment failed" )
```
or fancy with notifications:
```bash
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
ansible-playbook destroy_cluster.yml
```

