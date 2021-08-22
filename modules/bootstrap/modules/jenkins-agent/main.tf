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

/**************
 * Network
 **************/

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

resource "google_compute_address" "jenkins_agent_gce_static_ip" {
  // This internal IP address needs to be accessible via the VPN tunnel
  project      = module.cicd_project.project_id
  name         = "jenkins-agent-gce-static-ip"
  subnetwork   = google_compute_subnetwork.jenkins_agents_subnet.self_link
  address_type = "INTERNAL"
  address      = "172.16.1.6"
  region       = var.region
  purpose      = "GCE_ENDPOINT"
  description  = "The static Internal IP address of the Jenkins Agent"
}

resource "google_compute_firewall" "fw_allow_ssh_into_jenkins_agent" {
  project       = module.cicd_project.project_id
  name          = "fw-${google_compute_network.jenkins_agents.name}-1000-i-a-all-all-tcp-22"
  description   = "Allow the Jenkins Master (Client) to connect to the Jenkins Agents (Servers) using SSH."
  network       = google_compute_network.jenkins_agents.name
  source_ranges = ["10.1.0.6/32"]
  target_tags   = local.jenkins_gce_fw_tags
  priority      = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}


/******************************************
  NAT Cloud Router & NAT config
 *****************************************/

resource "google_compute_router" "nat_router_region1" {
  name    = "cr-${google_compute_network.jenkins_agents.name}-${var.region}-nat-router"
  project = module.cicd_project.project_id
  region  = var.region
  network = google_compute_network.jenkins_agents.self_link

  bgp {
    asn = "64514"
  }
}

resource "google_compute_address" "nat_external_addresses1" {
  name    = "cn-${google_compute_network.jenkins_agents.name}-${var.region}"
  project = module.cicd_project.project_id
  region  = var.region
}

resource "google_compute_router_nat" "nat_external_addresses_region1" {
  project                            = module.cicd_project.project_id
  name                               = "rn-${google_compute_network.jenkins_agents.name}-${var.region}-egress"
  router                             = google_compute_router.nat_router_region1.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat_external_addresses1.*.self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    filter = "TRANSLATIONS_ONLY"
    enable = true
  }
}


/**************
 * Jenkins
 **************/

/**
 * This will create the jenkins agent
 */
resource "google_compute_instance" "jenkins_agent_gce_instance" {
  project      = module.cicd_project.project_id
  name         = "jenkins-agent-01"
  machine_type = "n1-standard-1"
  zone         = "${var.region}-a"
  tags = local.jenkins_gce_fw_tags
  boot_disk {
    initialize_params {
      // It is better if user has a golden image with all necessary packages.
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    // Internal and static IP configuration
    subnetwork = google_compute_subnetwork.jenkins_agents_subnet.self_link
    network_ip = google_compute_address.jenkins_agent_gce_static_ip.address
  }

  // Adding ssh public keys to the GCE instance metadata, so the Jenkins Master can connect to this Agent
  metadata = {
    enable-oslogin = "false"
    ssh-keys       = var.jenkins_agent_gce_ssh_pub_key
  }

  metadata_startup_script = data.template_file.jenkins_agent_gce_startup_script.rendered

  service_account {
    email = google_service_account.jenkins_agent_gce_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  // allow stopping the GCE instance to update some of its values
  allow_stopping_for_update = true
}

/******************************************
  Jenkins IAM for admins
*******************************************/

resource "google_project_iam_member" "org_admins_jenkins_admin" {
  project = module.cicd_project.project_id
  role    = "roles/compute.admin"
  member  = "group:${var.group_org_admin}"
}

resource "google_project_iam_member" "org_admins_jenkins_viewer" {
  project = module.cicd_project.project_id
  role    = "roles/viewer"
  member  = "group:${var.group_org_admin}"
}

/******************************************
  Jenkins Artifact bucket
*******************************************/

resource "google_storage_bucket" "gcs_jenkins_artifacts" {
  project                     = module.cicd_project.project_id
  name                        = format("%s-%s-%s-%s", "bkt", module.cicd_project.project_id, "jenkins-artifacts", random_id.suffix.hex)
  location                    = var.region
  labels                      = {
    environment       = "bootstrap"
    application_name  = "bucket-jenkins-academeez"
    billing_code      = "1234"
    business_code     = "abcd"
    env_code          = "b"
  }
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

/***********************************************
  Jenkins - IAM
 ***********************************************/

// Allow the Jenkins Agent (GCE Instance) custom Service Account to store artifacts in GCS
// The pipeline must use gsutil to store artifacts in the GCS bucket
resource "google_storage_bucket_iam_member" "jenkins_artifacts_iam" {
  bucket = google_storage_bucket.gcs_jenkins_artifacts.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.jenkins_agent_gce_sa.email}"
}

// Allow the Jenkins Agent (GCE Instance) custom Service Account to impersonate the Terraform Service Account
resource "google_service_account_iam_member" "jenkins_terraform_sa_impersonate_permissions" {
  count = local.impersonation_enabled_count

  service_account_id = var.terraform_sa_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.jenkins_agent_gce_sa.email}"
}

resource "google_organization_iam_member" "jenkins_serviceusage_consumer" {
  count = local.impersonation_enabled_count

  org_id = var.org_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "serviceAccount:${google_service_account.jenkins_agent_gce_sa.email}"
}

# Required to allow jenkins Service Account to access state with impersonation.
resource "google_storage_bucket_iam_member" "jenkins_state_iam" {
  count = local.impersonation_enabled_count

  bucket = var.terraform_state_bucket
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.jenkins_agent_gce_sa.email}"
}
