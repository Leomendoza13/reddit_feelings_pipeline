variable "your_ip_adress" {
  description = "Ip adress of your local machine"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for connecting to instances"
  type        = string
  default     = "default-ssh-user"
}

variable "ssh_pub_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}