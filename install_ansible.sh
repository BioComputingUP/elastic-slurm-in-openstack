#!/bin/bash

python3 -m venv ansible
source ./ansible/bin/activate

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

ansible-galaxy install -r requirements.yml
