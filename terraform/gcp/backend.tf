terraform {
  backend "gcs" {
    bucket = "cyber-analyzer-tfstate"
    prefix = "terraform/state"
  }
}
