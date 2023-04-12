provider "google" {
  credentials = file("./terpel-infra-iac-demo-393093fddaf5.json")
  project     = "${var.project}"
  region      = "us-east1"
  zone        = "us-east1-b"
}


resource "google_compute_instance" "vm_instance" {
  name         = "mi-vm"
  machine_type = "e2-medium"
  tags         = ["m2c-dev-allow-ingress-from-iap", "allow-rdp"]

  boot_disk {
    initialize_params {
      # image = "windows-server-2019-dc-core-v20200609"
      image = "windows-server-2019-dc-v20230315"
    }
  }
  network_interface {
    network    = "projects/terpel-infra-sharedvpc-dev/global/networks/vpc-dev"
    subnetwork = "projects/terpel-infra-sharedvpc-dev/regions/us-east1/subnetworks/nodes-landing-m2c-infra-dev"
  }

  # metadata_startup_script = <<-EOF
  #   Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
  #   #!/usr/bin/env powershell
  #   # Instalar Git Bash
  #   Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.33.1.windows.1/Git-2.33.1-64-bit.exe' -OutFile 'C:\git.exe'
  #   Start-Process -FilePath 'C:\git.exe' -ArgumentList '/VERYSILENT /NORESTART /SP-' -Wait
  #   Remove-Item -Path 'C:\git.exe'

  #   # Instalar el agente Qualys Cloud
  #   Invoke-WebRequest -Uri 'https://qagpublicdownloads.blob.core.windows.net/agent/QualysCloudAgent.exe' -OutFile 'C:\QualysCloudAgent.exe'
  #   Start-Process -FilePath 'C:\QualysCloudAgent.exe' -ArgumentList '/s' -Wait
  #   Remove-Item -Path 'C:\QualysCloudAgent.exe'
  # EOF


}

resource "google_compute_instance_iam_binding" "viewer" {
  # project        = "PROJECT_ID"
  instance_name = google_compute_instance.vm_instance
  role          = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${var.terraform-sa}"
  ]
}

# resource "google_service_account" "terraform" {
#   account_id   = "terraform"
#   display_name = "Terraform Service Account"
# }

resource "google_project_iam_member" "viewer" {
  #project = "PROJECT_ID"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${var.terraform-sa}"
}

resource "google_storage_bucket_iam_binding" "viewer" {
  bucket = "iac-demo-bucket"
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${var.terraform-sa}",
    "serviceAccount:${google_compute_instance.vm_instance.service_account}"
  ]
}