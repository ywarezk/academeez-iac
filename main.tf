/**
 * Entry point file for the IAC terraform project
 *
 * Created August 19th, 2021
 * @author: ywarezk
 * @version: 0.0.1
 * @license MIT
 */

provider "google-beta" {
  region      = var.region
  user_project_override = true
  billing_project = var.billing_account
}

provider "github" {
}

/**
 * Create the root folder of the project
 */
module "root_folder" {
  source  = "terraform-google-modules/folders/google"
  version = "~> 3.0"

  parent  = "organizations/${var.org_id}"

  names = [ "academeez" ]

  # list of admins for a specific folder
  # per_folder_admins = {}

  # these admins will have admin for all the folders and subfolders
  # you can also set a group here
  all_folder_admins = [
    "yariv@nerdeez.com"
  ]

  #  Use this to add more roles to folder admins
  # folder_admin_roles = [
  #   "roles/owner",
  #   "roles/resourcemanager.folderViewer",
  #   "roles/resourcemanager.projectCreator",
  #   "roles/compute.networkAdmin"
  # ]
}

/**
 * Activate the bootstrap module for creating terraform and jenkins
 */
module "bootstrap" {
  source = "./modules/bootstrap"
  parent_folder = module.root_folder.id
  org_id = var.org_id
  billing_account = var.billing_account
}

data "github_repository" "academeez_repo" {
  full_name = "ywarezk/academeez"
}

/*
# this is how to create a secret on github
resource "github_actions_secret" "test_secret" {
  repository       = data.github_repository.academeez_repo.name
  secret_name      = "test_secret"
  plaintext_value  = var.test_secret
}
*/

module "environments" {
  for_each = var.environments
  source = "./modules/env"
  env_name = each.key
}
