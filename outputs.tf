output "awx_ips" {
  value = digitalocean_droplet.awx_server.*.ipv4_address
}

output "managed_node_ips" {
  value = digitalocean_droplet.managed_node.*.ipv4_address
}

output "participant_machine_ips" {
  value = {
    for p in range(var.num_participants) :
    p => {
      c_awx    = digitalocean_droplet.awx_server[p].ipv4_address
      d_nodes  = [for n in range(var.machines_per_participant - 1) : digitalocean_droplet.managed_node[p * (var.machines_per_participant - 1) + n].ipv4_address]
      a_awx_url = try(local.awx_details["awx_url_${p}"], "")
      b_awx_pass = try(local.awx_details["awx_admin_password_${p}"], "")
    }
  }
}