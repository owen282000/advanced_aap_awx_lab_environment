#!/bin/bash

# Voor WSL...
dos2unix * && dos2unix */* && dos2unix */*/* && dos2unix */*/*/* > /dev/null 2>&1
chmod +x apply_with_output.sh && chmod +x scripts/extract_awx_details.sh && chmod +x scripts/setup_ansible.sh > /dev/null 2>&1

# Copy awx_details.json.template to awx_details.json if there is no difference or if awx_details.json does not exist
if [ ! -f awx_details.json ] || diff awx_details.json awx_details.json.template > /dev/null; then
  cp awx_details.json.template awx_details.json
fi

# Initialiseer Terraform
terraform init

# Voer Terraform apply uit en capture the output while also printing it live to the terminal
apply_output=$(mktemp)
terraform apply -auto-approve 2>&1 | tee $apply_output

# Check for the specific error message in the output
if grep -q "Provider produced inconsistent final plan" $apply_output; then
  echo "Inconsistent final plan detected, reapplying Terraform..."
  terraform apply -auto-approve
fi

# Remove the temporary file
rm $apply_output

# Capture the participant_machine_ips output to a JSON file
terraform output -json participant_machine_ips > participant_machine_ips.json
cat participant_machine_ips.json | jq