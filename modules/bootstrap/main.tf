/**
 * Entry point for bootstrap module
 *
 * Created August 20th, 2021
 * @author: ywarezk
 * @version: 0.0.1
 * @license: MIT
 */

/**
 * Create a bootstrap folder
 */
module "bootstrap_folder" {
  source  = "terraform-google-modules/folders/google"
  parent  = var.parent_folder
  names = [ "bootstrap" ]
}

/**
 * Create the project that will hold ci
 */
module "bootstrap_project" {
  source                      = "terraform-google-modules/project-factory/google"
  name                        = "prj-b-bootstrap"
  random_project_id           = true
  disable_services_on_destroy = false
  folder_id                   = module.bootstrap_folder.id
  org_id                      = var.org_id
  billing_account             = var.billing_account
  activate_apis               = [
    "storage.googleapis.com",
    "billingbudgets.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudidentity.googleapis.com"
  ]
  labels                      = {
    environment       = "bootstrap"
    application_name  = "bootstrap"
    billing_code      = "1235"
    business_code     = "abce"
    env_code          = "b"
  }
}

/**
 * the terraform state will be placed in this private bucket
 */
resource "google_storage_bucket" "tf_state_bucket" {
  name          = "bkt-b-tf-state"
  location      = "US"
  project       = module.bootstrap_project.project_id
}

/**
 * Create a service account to use to run terraform commands
 */
resource "google_service_account" "service_account" {
  account_id   = "sa-terraform"
  display_name = "Terraform Service Account"
  project = module.bootstrap_project.project_id
}

/**
 * group of principals that can modify terraform
 */
module "terraform_admins" {
  source       = "terraform-google-modules/group/google"
  id           = "grp-terraform-admins@nerdeez.com"
  display_name = "Terraform Admins"
  description  = "Users with terraform privilages"
  domain       = "nerdeez.com"
  owners       = [
    "yariv@nerdeez.com"
  ]
  members = var.terraform_admins
}

