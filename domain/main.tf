terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
 # Cloudflare email saved in $CLOUDFLARE_EMAIL
 # Cloudflare API token saved in $CLOUDFLARE_API_TOKEN
}
