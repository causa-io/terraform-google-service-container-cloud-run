terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.1.0, < 8.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1, < 4.0"
    }
  }
}
