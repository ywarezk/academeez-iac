/**
 * Represents a single environment in academeez: dev/prod...
 *
 * Created December 17th, 2021
 * @author: ywarezk
 * @copyright: Nerdeez LTD
 * @version: 0.0.1
 */

/**
 * Create the folder where all the environments are placed
 */
module "env_folder" {
  source  = "terraform-google-modules/folders/google"
  parent  = "folders/624492365583" # parent is always the root folder
  names = [
    var.env_name # dev/prod/...
  ]
}

/**
 * Create a project for the environment
 */
module "env_project" {
  source                      = "terraform-google-modules/project-factory/google"
  name                        = "prj-e-${var.env_name}"
  random_project_id           = true
  disable_services_on_destroy = false
  folder_id                   = module.env_folder.id
  org_id                      = var.org_id
  billing_account             = var.billing_account
  budget_amount               = var.budget_amount
  create_project_sa           = false
  activate_apis               = [
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudidentity.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
  labels                      = {
    environment       = var.env_name
    application_name  = "academeez"
    env_code          = "e"
  }
}

/**
 * Create the network for the cluster
 */
module "env_network" {
  source       = "terraform-google-modules/network/google"
  project_id   = module.env_project.project_id
  network_name = "vpc-e-${var.env_name}"

  subnets = [
    {
      subnet_name   = "sb-${var.env_name}"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    "sb-${var.env_name}" = [
      {
        range_name    = "sb-range-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "sb-range-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}
