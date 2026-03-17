terraform {
  backend "gcs" {
    # We leave these empty because we are passing 
    # them via -backend-config in the shell script
  }
}
