resource "hcp_hvn" "hvn" {
  hvn_id         = "hashicraft"
  cloud_provider = "aws"
  region         = "eu-west-1"
}