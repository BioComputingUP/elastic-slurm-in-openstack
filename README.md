# Slurm cluster in OpenStack cloud
These Ansible playbooks create and manage a dynamically allocated (elastic) Slurm cluster in an OpenStack cloud.
The cluster is based on CentOS 8 (Rocky 8) and [OpenHPC 2.x](https://openhpc.community/downloads/). Slurm configurations are based on the work contained 
in [Jetstream_Cluster](https://github.com/XSEDE/CRI_Jetstream_Cluster).

This repo is based on the project [slurm-cluster-in-openstack](https://github.com/CornellCAC/slurm-cluster-in-openstack)
adapted for use with [CloudVeneto](https://cloudveneto.ict.unipd.it/) OpenStack cloud.

Run the following Ansible playbooks on your local PC, not on a Virtual Machine in the OpenStack cloud. 
Ensure your local machine is set up with the necessary keys and access credentials for the target OpenStack environment. 
Once the playbooks are executed, you'll have access to your personal elastic Slurm cluster in the cloud.

## Prerequisites
### Install Ansible
Run the `install_ansible.sh` command:
```bash
./install_ansible.sh
```

### Configure CloudVeneto gateway (Gate) for SSH access
For this you should have a CloudVeneto account and access to the Gate machine (`cv_user` and `cv_pass`):
```bash
# generate a new key pair locally (preferably with passphrase). Skip and adapt if you already have a key pair:
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_vm

# copy the public key to Gate machine (it will ask for cv_pass):
cat ~/.ssh/id_ed25519_vm.pub | \
  ssh cv_user@gate.cloudveneto.it 'cat >id_ed25519_vm.pub && \
  mkdir -p .ssh && \
  chmod 700 .ssh && \
  mv id_ed25519_vm.pub .ssh/id_ed25519_vm.pub && \
  cat .ssh/id_ed25519_vm.pub >>.ssh/authorized_keys'

# copy the private key to Gate machine (it will ask for cv_pass):
cat ~/.ssh/id_ed25519_vm | \
  ssh cv_user@gate.cloudveneto.it \
  'cat >.ssh/id_ed25519_vm && chmod 600 .ssh/id_ed25519_vm'

# connect to Gate machine (it will ask for SSH key passphrase, if used):
ssh -i ~/.ssh/id_ed25519_vm cv_user@gate.cloudveneto.it
```
If you have also the credentials and IP of a VM running in the cloud (`vm_user`, `vm_pass`, `vm_ip`), you can import the key pair to it:
```bash
# copy the public key from the Gate machine to VM (it will ask for vm_pass)
cat ~/.ssh/id_ed25519_vm.pub | \
  ssh vm_user@vm_ip 'cat >.ssh/id_ed25519_vm.pub && \
  cat .ssh/id_ed25519_vm.pub >>.ssh/authorized_keys'

# test connection to VM from Gate machine (it will ask for SSH passphrase, if used)
ssh -i ~/.ssh/id_ed25519_vm vm_user@vm_ip
exit
```
Accessing a VM from your local machine requires proxying the SSH connection through the CloudVeneto Gate. You can achieve this by using the following SSH command:
```bash
# (optionally) add key to ssh-agent (it may ask for SSH key passphrase)
ssh-add ~/.ssh/id_ed25519_vm

# connect to VM via proxy
ssh -i ~/.ssh/id_ed25519_vm \
  -o StrictHostKeyChecking=accept-new \
  -o ProxyCommand="ssh -i ~/.ssh/id_ed25519_vm \
  -W %h:%p cv_user@gate.cloudveneto.it" \
  vm_user@vm_ip
```
You can simplify the SSH connection to VM by configuring your SSH config file:
```bash
# update ssh config with proxy and headnode
cat <<EOF | tee -a ~/.ssh/config

Host cvgate
	HostName gate.cloudveneto.it
	User cv_user
	IdentityFile ~/.ssh/id_ed25519_vm

Host vm
	HostName vm_ip
	User vm_user
	IdentityFile ~/.ssh/id_ed25519_vm
	UserKnownHostsFile /dev/null
	StrictHostKeyChecking=accept-new
	ProxyJump cvgate
EOF
```
Test the connection:
```bash
# connect to VM
ssh vm

# copy files to and from VM with scp
scp localdir/file vm:remotedir/
scp vm:remotedir/file localdir/
# or rsync
rsync -ahv localdir/ vm:remotedir/
rsync -ahv vm:remotedir/ localdir/
```

## Deploy Slurm Cluster
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

