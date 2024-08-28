#!/bin/bash

python3 -m venv ansible
source ./ansible/bin/activate

pip install --upgrade pip wheel
pip install --upgrade 'ansible<10' python-openstackclient openstacksdk==0.52.0

ansible-galaxy install -r requirements.yml
