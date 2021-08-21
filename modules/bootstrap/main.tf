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
 * the terraform-google-modules bootstrap module will create the following:
 * - Create a project for terraform
 * - Enable api's in that project
 * - create a service account for terraform
 * - Create a bucket for terraform state
 * - IAM permissions
 */
module "seed_bootstrap" {

  source = "terraform-google-modules/bootstrap/google"
  version = "~> 2.1"
  # org_id = var.org_id
  org_id = "701515151774"
  folder_id = module.bootstrap_folder.id
  project_id = "prj-b-seed"
  state_bucket_name = "bkt-b-tfstate"
  billing_account = var.billing_account
  group_org_admins = var.group_org_admin
  group_billing_admins = var.group_billing_admins
  default_region = var.region
  sa_enable_impersonation = true
  parent_folder = module.bootstrap_folder.id
  org_admins_org_iam_permissions = [
    "roles/orgpolicy.policyAdmin", "roles/resourcemanager.organizationAdmin", "roles/billing.user"
  ]
  project_prefix = "prj"
  project_labels = {
    environment       = "bootstrap"
    application_name  = "seed-bootstrap"
    billing_code      = "1234"
    business_code     = "abcd"
    env_code          = "b"
  }
  activate_apis = [
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "admin.googleapis.com",
    "appengine.googleapis.com",
    "storage-api.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "securitycenter.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "billingbudgets.googleapis.com"
  ]
  sa_org_iam_permissions = [
    "roles/accesscontextmanager.policyAdmin",
    "roles/billing.user",
    "roles/compute.networkAdmin",
    "roles/compute.xpnAdmin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/logging.configWriter",
    "roles/orgpolicy.policyAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.folderAdmin",
    "roles/securitycenter.notificationConfigEditor",
    "roles/resourcemanager.organizationViewer"
  ]
}
