variable "terraform-sa" {
  description = "terraform service account"
  type        = string
  default     = "terraform@terpel-infra-iac-demo.iam.gserviceaccount.com"
}

variable "project" {
  type = string
  default = "terpel-infra-iac-demo"
}

variable "credentials-path" {
  type = string
}