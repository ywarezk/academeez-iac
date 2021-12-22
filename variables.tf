/**
 * Define the main variables here
 *
 * Created August 19th, 2021
 * @author: ywarezk
 * @version: 0.0.1
 */

variable "region" {
  description = "The region where the infastructure will be"
  type        = string
  default     = "us-central1"
}

variable "org_id" {
  description = "The id of the organization"
  type        = string
  default     = "701515151774"
}

variable "billing_account" {
  description = "Billing accound of the infastructure"
  type        = string
  default     = "01187F-6BAFD6-F8EE32"
}

variable "environments" {
  description = "Environments object"
  type        = map(any)
  default = {
    dev = {
      budget_amount              = 100
      horizontal_pod_autoscaling = false
      # change this in production you cheap fuck!
      machine_type               = "e2-micro"
      min_count                  = 1
      max_count                  = 1
      initial_node_count         = 1

      #  should be set to ssd on production
      disk_type = "pd-standard"

      # on production this should be set to false
      preemptible = true

      # Set to warsaw for cheapest prices, for production set to use
      region = "europe-central2"

      # in production: ["us-central1-a", "us-central1-b", "us-central1-f"]
      zones = []
    }
  }
}
