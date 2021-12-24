/**
 * Entry point file for the IAC terraform project
 *
 * Created August 19th, 2021
 * @author: ywarezk
 * @version: 0.0.1
 * @license MIT
 */

provider "github" {
}

provider "google-beta" {
  region          = var.region
}

/**
 * Create the root folder of the project
 */
module "root_folder" {
  source  = "terraform-google-modules/folders/google"

  parent = "organizations/${var.org_id}"

  names = ["academeez"]

  # list of admins for a specific folder
  # per_folder_admins = {}

  # these admins will have admin for all the folders and subfolders
  # you can also set a group here
  all_folder_admins = [
    "yariv@nerdeez.com"
  ]
}

/**
 * Activate the bootstrap module for creating terraform and jenkins
 */
module "academeez_common" {
  source          = "./modules/common"
  parent_folder   = module.root_folder.id
  org_id          = var.org_id
  billing_account = var.billing_account
}

# data "github_repository" "academeez_repo" {
#   full_name = "ywarezk/academeez"
# }

# /*
# # this is how to create a secret on github
# resource "github_actions_secret" "test_secret" {
#   repository       = data.github_repository.academeez_repo.name
#   secret_name      = "test_secret"
#   plaintext_value  = var.test_secret
# }
# */

module "environments" {
  for_each    = var.environments
  source      = "./modules/env"
  env_name    = each.key
  env_options = each.value
}
