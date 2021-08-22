/**
 * Define the main variables here
 *
 * Created August 19th, 2021
 * @author: ywarezk
 * @version: 0.0.1
 */

variable "region" {
  description = "The region where the infastructure will be"
  type = string
}

variable "org_id" {
  description = "The id of the organization"
  type = string
}

variable "billing_account" {
  description = "Billing accound of the infastructure"
  type = string
}

variable "jenkins_agent_gce_ssh_pub_key" {
  description = "SSH public key needed by the Jenkins Agent GCE Instance. The Jenkins Master holds the SSH private key. The correct format is `'ssh-rsa [KEY_VALUE] [USERNAME]'`"
  type        = string
}
