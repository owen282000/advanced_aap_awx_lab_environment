#!/bin/bash

num_participants=$1
IFS=',' read -r -a awx_ips <<< "$2"
IFS=',' read -r -a managed_ips <<< "$3"

total_managed_nodes=${#managed_ips[@]}
total_awx_nodes=${#awx_ips[@]}
managed_nodes_per_participant=$((total_managed_nodes / total_awx_nodes))

export ANSIBLE_CONFIG=./setup/ansible.cfg
all_awx_hosts=()

for p in $(seq 0 $((num_participants - 1))); do
  inventory_dir="setup/inventory/participant_${p}"
  mkdir -p $inventory_dir

  echo '[awx_servers]' > $inventory_dir/hosts
  echo "awx-1 ansible_host=${awx_ips[$p]}" >> $inventory_dir/hosts

  echo '[managed_nodes]' >> $inventory_dir/hosts
  for n in $(seq 0 $((managed_nodes_per_participant - 1))); do
    node_index=$((p * managed_nodes_per_participant + n))
    echo "node-$((n + 1)) ansible_host=${managed_ips[$node_index]}" >> $inventory_dir/hosts
  done

  all_awx_hosts+=("${awx_ips[$p]}")

  ansible-playbook -i $inventory_dir/hosts setup/playbooks/prepare_nodes.yml
done

combined_inventory="setup/inventory/all_awx_hosts"
mkdir -p $combined_inventory

echo '[awx_servers]' > $combined_inventory/hosts
for awx_host in "${all_awx_hosts[@]}"; do
  echo "awx-$awx_host ansible_host=$awx_host" >> $combined_inventory/hosts
done

ansible-playbook -i $combined_inventory/hosts setup/playbooks/setup_awx.yml
