/**
 * Variables needed for creating the jenkins agent
 *
 * Created August 22nd, 2021
 * @author: ywarezk
 * @version: 0.0.1
 * @license: MIT
 */

variable "folder_id" {
  description = "The bootstrap folder"
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

variable "jenkins_agent_gce_ssh_pub_key" {
  description = "SSH public key needed by the Jenkins Agent GCE Instance. The Jenkins Master holds the SSH private key. The correct format is `'ssh-rsa [KEY_VALUE] [USERNAME]'`"
  type        = string
}

variable "region" {
  description = "The region where the infastructure will be"
  type = string
}

variable "group_org_admin" {
  description = "Group id of the admins"
  type = string
}

variable "terraform_sa_name" {
  description = "Fully-qualified name of the terraform service account. It must be supplied by the seed project"
  type        = string
}

variable "terraform_state_bucket" {
  description = "Default state bucket, used in Cloud Build substitutions. It must be supplied by the seed project"
  type        = string
}
