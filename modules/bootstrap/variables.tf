/**
 * Variables for the bootstrap module
 *
 * Created August 20th, 2021
 * @author: ywarezk
 * @version: 0.0.1
 * @license: MIT
 */

variable "parent_folder" {
  description = "The id of the academeez folder"
  type = string
}

variable "org_id" {
  description = "Organization Id"
  type = string
}

variable "billing_account" {
  description = "billing account"
  type = string
}

variable "nerdeez_domain" {
  description = "Nerdeez Domain"
  default = "nerdeez.com"
  type = string
}

variable "group_org_admin" {
  description = "Group id of the admins"
  default = "grp-gcp-org-admin@nerdeez.com"
  type = string
}

variable "group_billing_admins" {
  description = "Group for the billing admins"
  type = string
  default = "grp-gcp-org-billing-admins@nerdeez.com"
}

variable "region" {
  description = "The region where the infastructure will be"
  type = string
}

variable "jenkins_agent_gce_ssh_pub_key" {
  description = "SSH public key needed by the Jenkins Agent GCE Instance. The Jenkins Master holds the SSH private key. The correct format is `'ssh-rsa [KEY_VALUE] [USERNAME]'`"
  type        = string
}
