#!/bin/bash

# This Ansible repo needs Python 3.10
# using conda:
# conda create -y -n ansible-openstack python=3.10
# conda activate ansible-openstack
# or better using pyenv:
# pyenv virtualenv 3.10 ansible-openstack
# pyenv local ansible-openstack
# pyenv activate ansible-openstack

pip install --upgrade pip wheel
pip install --upgrade \
  ansible==9.2.0 \
  ansible-core==2.16.3 \
  python-openstackclient==5.4.0 \
  openstacksdk==0.52.0 \
  python-cinderclient==9.4.0 \
  python-keystoneclient==5.3.0 \
  python-novaclient==18.4.0 \
  python-openstackclient==5.4.0 \
  keystoneauth1==5.5.0

ansible-galaxy install -r requirements.yml --force