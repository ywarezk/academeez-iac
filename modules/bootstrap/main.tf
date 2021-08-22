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
  org_id = var.org_id
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

/**
 * Give role of billing admin to the terraform service account
 */
resource "google_billing_account_iam_member" "tf_billing_admin" {
  billing_account_id = var.billing_account
  role               = "roles/billing.admin"
  member             = "serviceAccount:${module.seed_bootstrap.terraform_sa_email}"
}

resource "google_organization_iam_member" "org_tf_compute_security_policy_admin" {
  org_id = var.org_id
  role   = "roles/compute.orgSecurityPolicyAdmin"
  member = "serviceAccount:${module.seed_bootstrap.terraform_sa_email}"
}

resource "google_folder_iam_member" "folder_tf_compute_security_policy_admin" {
  folder = var.parent_folder
  role   = "roles/compute.orgSecurityPolicyAdmin"
  member = "serviceAccount:${module.seed_bootstrap.terraform_sa_email}"
}

resource "google_organization_iam_member" "org_tf_compute_security_resource_admin" {
  org_id = var.org_id
  role   = "roles/compute.orgSecurityResourceAdmin"
  member = "serviceAccount:${module.seed_bootstrap.terraform_sa_email}"
}

resource "google_folder_iam_member" "folder_tf_compute_security_resource_admin" {
  folder = var.parent_folder
  role   = "roles/compute.orgSecurityResourceAdmin"
  member = "serviceAccount:${module.seed_bootstrap.terraform_sa_email}"
}

/****************
 * Jenkins
 ****************/

module "jenkins_bootstrap" {
 source                                  = "./modules/jenkins-agent"
 org_id                                  = var.org_id
 folder_id                               = module.bootstrap_folder.id
 billing_account                         = var.billing_account
 jenkins_agent_gce_ssh_pub_key = var.jenkins_agent_gce_ssh_pub_key
#  group_org_admins                        = var.group_org_admins
#  default_region                          = var.default_region
#  terraform_service_account               = module.seed_bootstrap.terraform_sa_email
#  terraform_sa_name                       = module.seed_bootstrap.terraform_sa_name
#  terraform_state_bucket                  = module.seed_bootstrap.gcs_bucket_tfstate
#  sa_enable_impersonation                 = true
#  jenkins_master_subnetwork_cidr_range    = var.jenkins_master_subnetwork_cidr_range
#  jenkins_agent_gce_subnetwork_cidr_range = var.jenkins_agent_gce_subnetwork_cidr_range
#  jenkins_agent_gce_private_ip_address    = var.jenkins_agent_gce_private_ip_address
#  nat_bgp_asn                             = var.nat_bgp_asn
#  jenkins_agent_sa_email                  = var.jenkins_agent_sa_email
#  jenkins_agent_gce_ssh_pub_key           = var.jenkins_agent_gce_ssh_pub_key
#  vpn_shared_secret                       = var.vpn_shared_secret
#  on_prem_vpn_public_ip_address           = var.on_prem_vpn_public_ip_address
#  on_prem_vpn_public_ip_address2          = var.on_prem_vpn_public_ip_address2
#  router_asn                              = var.router_asn
#  bgp_peer_asn                            = var.bgp_peer_asn
#  tunnel0_bgp_peer_address                = var.tunnel0_bgp_peer_address
#  tunnel0_bgp_session_range               = var.tunnel0_bgp_session_range
#  tunnel1_bgp_peer_address                = var.tunnel1_bgp_peer_address
#  tunnel1_bgp_session_range               = var.tunnel1_bgp_session_range
}

# resource "google_organization_iam_member" "org_jenkins_sa_browser" {
#   count  = var.parent_folder == "" ? 1 : 0
#   org_id = var.org_id
#   role   = "roles/browser"
#   member = "serviceAccount:${module.jenkins_bootstrap.jenkins_agent_sa_email}"
# }

# resource "google_folder_iam_member" "folder_jenkins_sa_browser" {
#   count  = var.parent_folder != "" ? 1 : 0
#   folder = var.parent_folder
#   role   = "roles/browser"
#   member = "serviceAccount:${module.jenkins_bootstrap.jenkins_agent_sa_email}"
# }
