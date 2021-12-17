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
