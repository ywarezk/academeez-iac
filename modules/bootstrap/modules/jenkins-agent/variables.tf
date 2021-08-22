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
