/**
 * Entry point - will create a jenkins agent
 *
 * Created August 22nd, 2021
 * @author: ywarezk
 * @version: 0.0.1
 * @license: MIT
 */


locals {
  cicd_project_name = "prj-b-cicd"
  impersonation_enabled_count = 1
  activate_apis = ["billingbudgets.googleapis.com"]
  jenkins_gce_fw_tags = ["ssh-jenkins-agent"]
}

resource "random_id" "suffix" {
  byte_length = 2
}

/**
 * Create the project for the jenkins agent
 */
module "cicd_project" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 10.1"
  name                        = local.cicd_project_name
  random_project_id           = true
  disable_services_on_destroy = false
  folder_id                   = var.folder_id
  org_id                      = var.org_id
  billing_account             = var.billing_account
  activate_apis               = local.activate_apis
  labels                      = {
    environment       = "bootstrap"
    application_name  = "seed-jenkins"
    billing_code      = "1234"
    business_code     = "abcd"
    env_code          = "b"
  }
}

/**
 * Create the service account for jenkins
 */
resource "google_service_account" "jenkins_agent_gce_sa" {
  project      = module.cicd_project.project_id
  account_id   = "sa-jenkins-agent-gce"
  display_name = "Jenkins Agent (GCE instance) custom Service Account"
}
