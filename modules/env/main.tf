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
  budget_amount               = var.env_options["budget_amount"]
  create_project_sa           = false
  activate_apis               = [
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudidentity.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com"
  ]
  labels                      = {
    environment       = var.env_name
    application_name  = "academeez"
    env_code          = "e"
  }
}

/**
 * Create the network for the cluster
 */
module "env_network" {
  source       = "terraform-google-modules/network/google"
  project_id   = module.env_project.project_id
  network_name = "vpc-e-${var.env_name}"

  subnets = [
    {
      subnet_name   = "sb-${var.env_name}"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.env_options["region"]
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    "sb-${var.env_name}" = [
      {
        range_name    = "sb-range-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "sb-range-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

/**
 * Create service account used by the nodes
 */
resource "google_service_account" "sa_env_cluster" {
  project      = module.env_project.project_id
  account_id   = "env-cluster"
  display_name = "Service account for the nodes in the cluster"
}

/**
 * each environment will have a kubernetes cluster
 */
# module "env_gke" {
#   source      = "terraform-google-modules/kubernetes-engine/google"
#   project_id  = module.env_project.project_id
#   name        = "gke-alison-${var.env_name}"
#   region      = var.region
#   zones       = ["us-central1-a", "us-central1-b", "us-central1-f"]
#   network = module.env_network.network_name
#   subnetwork = module.env_network.subnets_names[0]
#   ip_range_pods              = "sb-range-pods"
#   ip_range_services          = "sb-range-services"
#   http_load_balancing        = false
#   horizontal_pod_autoscaling = var.env_options["horizontal_pod_autoscaling"]
#   network_policy             = false
#   node_pools = [
#     {
#       name                      = "default-node-pool"
#       machine_type              = var.env_options["machine_type"]
#       min_count                 = var.env_options["min_count"]
#       max_count                 = var.env_options["max_count"]
#       initial_node_count        = var.env_options["initial_node_count"]
#       local_ssd_count           = 0
#       disk_size_gb              = 20
#       disk_type                 = var.env_options["disk_type"]
#       image_type                = "COS"
#       auto_repair               = true
#       auto_upgrade              = true
#       preemptible               = var.env_options["preemptible"]
#       service_account = google_service_account.sa_env_cluster.email
#     }
#   ]

#   node_pools_oauth_scopes = {
#     all = []

#     default-node-pool = [
#       "https://www.googleapis.com/auth/cloud-platform",
#       "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
#       "https://www.googleapis.com/auth/servicecontrol",
#       "https://www.googleapis.com/auth/service.management.readonly",
#       "https://www.googleapis.com/auth/devstorage.read_write"
#     ]
#   }

#   node_pools_labels = {
#     all = {}

#     default-node-pool = {
#       default-node-pool = true
#     }
#   }

#   node_pools_taints = {
#     all = []

#     default-node-pool = [
#       {
#         key    = "default-node-pool"
#         value  = true
#         effect = "PREFER_NO_SCHEDULE"
#       },
#     ]
#   }

#   node_pools_tags = {
#     all = []

#     default-node-pool = [
#       "default-node-pool",
#     ]
#   }
# }
