variable "cluster_id" {
  type        = string
  description = "Identifier used to generate resources"
  default     = "win-test"
}

variable "admin_pw" {
  type        = string
  sensitive   = true
  description = "Admin password for windows nodes - mandatory"
}
