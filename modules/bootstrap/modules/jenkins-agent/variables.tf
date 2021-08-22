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
