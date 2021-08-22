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

/**
 * This data will be used to trigger the init script in the jenkins agent
 */
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

resource "google_compute_network" "jenkins_agents" {
  project = module.cicd_project.project_id
  name    = "vpc-b-jenkinsagents"
}

resource "google_compute_subnetwork" "jenkins_agents_subnet" {
  project       = module.cicd_project.project_id
  name          = "sb-b-jenkinsagents-${var.region}"
  ip_cidr_range = "172.16.1.0/24"
  region        = var.region
  network       = google_compute_network.jenkins_agents.self_link
}

/**
 * This will create the jenkins agent
 */
# resource "google_compute_instance" "jenkins_agent_gce_instance" {
#   project      = module.cicd_project.project_id
#   name         = "jenkins-agent-01"
#   machine_type = "n1-standard-1"
#   zone         = "${var.region}-a"
#   tags = local.jenkins_gce_fw_tags
#   boot_disk {
#     initialize_params {
#       // It is better if user has a golden image with all necessary packages.
#       image = "debian-cloud/debian-9"
#     }
#   }

#   network_interface {
#     // Internal and static IP configuration
#     subnetwork = google_compute_subnetwork.jenkins_agents_subnet.self_link
#     network_ip = google_compute_address.jenkins_agent_gce_static_ip.address
#   }

#   // Adding ssh public keys to the GCE instance metadata, so the Jenkins Master can connect to this Agent
#   metadata = {
#     enable-oslogin = "false"
#     ssh-keys       = var.jenkins_agent_gce_ssh_pub_key
#   }

#   metadata_startup_script = data.template_file.jenkins_agent_gce_startup_script.rendered

#   service_account {
#     email = google_service_account.jenkins_agent_gce_sa.email
#     scopes = [
#       "https://www.googleapis.com/auth/cloud-platform",
#     ]
#   }

#   // allow stopping the GCE instance to update some of its values
#   allow_stopping_for_update = true
# }
