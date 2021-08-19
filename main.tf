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
}

/**
 * Create the root folder of the project
 */
module "root_folder" {
  source  = "terraform-google-modules/folders/google"
  version = "~> 3.0"

  parent  = var.org_id

  names = [ "academeez" ]
}
