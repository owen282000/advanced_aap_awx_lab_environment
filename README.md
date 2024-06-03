# Terraform Project voor AWX en Managed Nodes

## Overzicht
Dit project gebruikt Terraform en Ansible om virtuele machines aan te maken in Digital Ocean voor het hosten van AWX en managed nodes voor meerdere deelnemers. \
Het doel is om gemakkelijk zo veel omgevingen als gewenst op te spinnen in DO om te gebruiken als lab voor demo's en lab sessies.

## Let op!

   ```sh
   Vanwege de huidige structuur kun je geen nieuwe participant toevoegen aan een draaiende omgeving. Hiervoor moet je of een nieuwe omgeving aanmaken of een nieuwe destroy/apply doen.
   ```

## Voorbereiding

0. **Voor WSL...**
   ```sh
   chmod +x apply_with_output.sh && dos2unix apply_with_output.sh
1. **Generate ssh-key pair** 
   - Zorg dat je een keypair hebt gemaakt om hierin te gebruiken
   ```sh
   mkdir .ssh
   ssh-keygen
      ./.ssh/id_rsa
2. **Add Digital Ocean API key to main.tf**
   ```sh
   provider "digitalocean" {
     token = "**************************************************"
   }
3. **Personalize variables in terraform.tfvars**
   ```sh
   num_participants = 5                # How many environments are made
   machines_per_participant = 3        # How many machines per env (1 awx node, rest managed nodes)
   awx_size = "s-4vcpu-8gb-amd"        # AWX node size (DO sizing)
   managed_node_size = "s-1vcpu-1gb"   # Managed node size (DO sizing)

## Instructies


1. **Run terraform code and generate participant output**
   ```sh
   ./apply_with_output.sh
2. **Check the created environment details**
   -    On succesful run, check the participant_machine_ips.json, here you will get the details for the created environments

   ```sh
   cat participant_machine_ips.json | jq

   {
   "0": {
      "awx": "134.209.87.114",
      "awx_pass": "MZirorCV4gfqxSMp2lRtiyONbto3HPuv",
      "awx_url": "http://134.209.80.228:30738",
      "nodes": [
         "159.223.8.19",
         "157.245.75.178"
      ]
   },
   "1": {
      "awx": "209.38.42.214",
      "awx_pass": "aF3MWOfTvZRjTR5O7QWTS2o6jPZGZQRR",
      "awx_url": "http://165.232.83.64:31589",
      "nodes": [
         "188.166.80.209",
         "188.166.44.214"
      ]
   }
   }
3. **Delete environment**
   ```sh
   terraform destroy