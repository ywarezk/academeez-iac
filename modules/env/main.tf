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
  # budget_amount               = var.budget_amount
  create_project_sa           = false
  activate_apis               = [
    "billingbudgets.googleapis.com"
  ]
  labels                      = {
    environment       = var.env_name
    application_name  = "academeez"
    env_code          = "e"
  }
}

/*
resource "google_billing_budget" "budget" {
  billing_account = "01187F-6BAFD6-F8EE32"
  display_name = "Example Billing Budget"
  amount {
    specified_amount {
      currency_code = "USD"
      units = "100000"
    }
  }
  threshold_rules {
      threshold_percent =  0.5
  }
}
*/
