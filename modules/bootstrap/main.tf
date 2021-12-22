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
    "cloudidentity.googleapis.com",
    "serviceusage.googleapis.com",

    "containerregistry.googleapis.com",
    "sourcerepo.googleapis.com",
    "secretmanager.googleapis.com",
    "gmail.googleapis.com",

    "container.googleapis.com"
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
resource "google_service_account" "terraform_service_account" {
  account_id   = "sa-terraform"
  display_name = "Terraform Service Account"
  project = module.bootstrap_project.project_id
}

/**
 * the terraform service account can access the bucket
 */
resource "google_storage_bucket_iam_binding" "terraform_sa_allow_bucket" {
  bucket = google_storage_bucket.tf_state_bucket.name
  role = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.terraform_service_account.email}"
  ]
}

/**
 * the terraform service account can access folders
 */
resource "google_organization_iam_binding" "terraform_sa_folders_creators" {
  org_id  = "701515151774"
  role    = "roles/resourcemanager.folderCreator"

  members = [
    "serviceAccount:${google_service_account.terraform_service_account.email}"
  ]
}

/**
 * terraform service has service usage admin on organization
 */
resource "google_organization_iam_binding" "terraform_sa_serviceusage_admin" {
  org_id  = "701515151774"
  role    = "roles/serviceusage.serviceUsageAdmin"

  members = [
    "serviceAccount:${google_service_account.terraform_service_account.email}"
  ]
}

/**
 * browser permission for terraform
 */
resource "google_organization_iam_binding" "terraform_sa_browser" {
  org_id  = "701515151774"
  role    = "roles/browser"

  members = [
    "serviceAccount:${google_service_account.terraform_service_account.email}"
  ]
}

/**
 * organization admin for terraform
 */
resource "google_organization_iam_binding" "terraform_sa_organization_admin" {
  org_id  = "701515151774"
  role    = "roles/resourcemanager.organizationAdmin"

  members = [
    "serviceAccount:${google_service_account.terraform_service_account.email}"
  ]
}

/**
 * billing permission for terraform
 */
resource "google_organization_iam_binding" "terraform_sa_billing" {
  org_id  = "701515151774"
  role    = "roles/billing.admin"

  members = [
    "serviceAccount:${google_service_account.terraform_service_account.email}"
  ]
}

/**
 * service account user for terraform
 */
resource "google_organization_iam_binding" "terraform_sa_editor" {
  org_id  = "701515151774"
  role    = "roles/editor"

  members = [
    "serviceAccount:${google_service_account.terraform_service_account.email}"
  ]
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
    "yariv@nerdeez.com",
    "sa-terraform@prj-b-bootstrap-45d7.iam.gserviceaccount.com"
  ]
  members = var.terraform_admins
}

/**
 * group members can impersionate this service account
 */
resource "google_service_account_iam_binding" "terraform_sa_iam" {
  service_account_id = google_service_account.terraform_service_account.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "group:${module.terraform_admins.id}"
  ]
}

/**
 * Allow the terraform group to create tokens for impersionation
 */
resource "google_service_account_iam_binding" "terraform_sa_token_creator" {
    service_account_id = google_service_account.terraform_service_account.name
    role               = "roles/iam.serviceAccountTokenCreator"
    members = [
        "group:${module.terraform_admins.id}"
    ]
}

