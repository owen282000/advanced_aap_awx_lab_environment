variable "num_participants" {
  description = "Number of participants"
  type        = number
  default     = 1
}

variable "machines_per_participant" {
  description = "Number of machines per participant"
  type        = number
  default     = 3
}

variable "awx_size" {
  description = "Size of the AWX server"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "managed_node_size" {
  description = "Size of the managed nodes"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "awx_details_path" {
  default = "awx_details.json"
}