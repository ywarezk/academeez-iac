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

data "template_file" "jenkins_agent_gce_startup_script" {
  // Add Cloud NAT for the Agent to reach internet and download updates and necessary binaries
  // not needed  if user has a golden image with all necessary packages.
  template = file("${path.module}/files/jenkins_gce_startup_script.sh")
  vars = {
    tpl_TERRAFORM_DIR               = "/usr/local/bin/"
    tpl_TERRAFORM_VERSION           = "1.0.5"
    tpl_TERRAFORM_VERSION_SHA256SUM = "7ce24478859ab7ca0ba4d8c9c12bb345f52e8efdc42fa3ef9dd30033dbf4b561"
    tpl_SSH_PUB_KEY                 = var.jenkins_agent_gce_ssh_pub_key
  }
}
