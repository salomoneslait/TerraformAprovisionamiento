provider "google" {
  credentials = file("${var.credentials-path}")
  project     = "${var.project}"
  region      = "us-east1"
  zone        = "us-east1-b"
}


# Networking ----------
resource "google_compute_network" "vm_network" {
  name                    = "mi-red"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vm_subnet" {
  name          = "mi-subred"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vm_network.self_link
}

resource "google_compute_firewall" "rdp-firewall" {
  name    = "rdp-firewall"
  network = google_compute_network.vm_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ssh-firewall" {
  name    = "ssh-firewall"
  network = google_compute_network.vm_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Compute engine -----------------

# resource "google_compute_instance" "vm_instance" {
#   name         = "mi-vm"
#   machine_type = "e2-medium"
#   tags         = ["m2c-dev-allow-ingress-from-iap"]

#   boot_disk {
#     initialize_params {
#       image = "windows-server-2019-dc-v20230315"
#     }
#   }
#   network_interface {
#     network    = "projects/terpel-infra-sharedvpc-dev/global/networks/vpc-dev"
#     subnetwork = "projects/terpel-infra-sharedvpc-dev/regions/us-east1/subnetworks/nodes-landing-m2c-infra-dev"
#   }
  
#   service_account {
#     #email  = "${google_service_account.windows-instance-sa.email}"
#     email  = "windows-service-account@terpel-infra-iac-demo.iam.gserviceaccount.com"
#     scopes = ["userinfo-email", "compute-ro", "storage-ro"]
#   }

#   # metadata_startup_script = <<-EOF
#   #   Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
#   #   #!/usr/bin/env powershell
#   #   # Instalar Git Bash
#   #   Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.33.1.windows.1/Git-2.33.1-64-bit.exe' -OutFile 'C:\git.exe'
#   #   Start-Process -FilePath 'C:\git.exe' -ArgumentList '/VERYSILENT /NORESTART /SP-' -Wait
#   #   Remove-Item -Path 'C:\git.exe'

#   #   # Instalar el agente Qualys Cloud
#   #   Invoke-WebRequest -Uri 'https://qagpublicdownloads.blob.core.windows.net/agent/QualysCloudAgent.exe' -OutFile 'C:\QualysCloudAgent.exe'
#   #   Start-Process -FilePath 'C:\QualysCloudAgent.exe' -ArgumentList '/s' -Wait
#   #   Remove-Item -Path 'C:\QualysCloudAgent.exe'
#   # EOF


# }

resource "google_compute_instance" "vm_instance_linux" {
  name         = "mi-vm-test"
  machine_type = "e2-medium"
  tags         = ["m2c-dev-allow-ingress-from-iap", "https", "http"]

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20230113"
    }
  }
  network_interface {
    # network    = "projects/terpel-infra-sharedvpc-dev/global/networks/vpc-dev"
    # subnetwork = "projects/terpel-infra-sharedvpc-dev/regions/us-east1/subnetworks/nodes-landing-m2c-infra-dev"
    network = google_compute_network.vm_network.id
    subnetwork = google_compute_subnetwork.vm_subnet.id
  }
  
  service_account {
    #email  = "${google_service_account.windows-instance-sa.email}"
    email  = google_service_account.linux-instance-sa.email
    #scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  labels = {
    http-server = "true"
  }

}

# Bucket -----------------------

resource "google_storage_bucket" "bucket" {
  name     = "metadata-test-234523"
  location = "us-east1"

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
}

# IAM ---------------------------

resource "google_storage_bucket_iam_member" "member" {
  bucket = "metadata-test-234523"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.linux-instance-sa.email}"

  depends_on = [
    google_compute_instance.vm_instance_linux
  ]
}

# Service accounts ---------------

resource "google_service_account" "windows-instance-sa" {
  project = var.project
  account_id   = "windows-instance-sa"
  display_name = "Windows Instance Service Account"
}

resource "google_service_account" "linux-instance-sa" {
  project = var.project
  account_id   = "linux-instance-sa"
  display_name = "linux Instance Service Account"
}

resource "google_storage_bucket_iam_binding" "viewer" {
  bucket = google_storage_bucket.bucket.id
  role   = "roles/storage.objectViewer"

  members = [
    #"serviceAccount:${var.terraform-sa}",
    "serviceAccount:${google_service_account.linux-instance-sa.email}"
  ]
}

# resource "google_service_networking_connection" "connection" {
#   network                 = "projects/terpel-infra-sharedvpc-dev/global/networks/vpc-dev"
#   service                 = "storage.googleapis.com"
#   reserved_peering_ranges = ["10.0.0.0/28"]
# }
