provider "google" {
  credentials = "${file("./terpel-infra-iac-demo-393093fddaf5.json")}"
  project = "terpel-infra-iac-demo"
  region  = "us-east1"
  zone    = "us-east1-b"
}

resource "google_compute_network" "vm_network" {
  name                    = "mi-red"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vm_subnet" {
  name          = "mi-subred"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vm_network.self_link
}

resource "google_compute_firewall" "vm_firewall" {
  name    = "mi-firewall"
  network = google_compute_network.vm_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_instance" "vm_instance" {
  name         = "mi-vm"
  machine_type = "n1-standard-1"
  boot_disk {
    initialize_params {
      image = "windows-server-2019-dc-core-v20200609"
    }
  }
  network_interface {
    network    = google_compute_network.vm_network.self_link
    subnetwork = google_compute_subnetwork.vm_subnet.self_link
    # access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/usr/bin/env powershell
    # Instalar Git Bash
    Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.33.1.windows.1/Git-2.33.1-64-bit.exe' -OutFile 'C:\git.exe'
    Start-Process -FilePath 'C:\git.exe' -ArgumentList '/VERYSILENT /NORESTART /SP-' -Wait
    Remove-Item -Path 'C:\git.exe'
    
    # Instalar el agente Qualys Cloud
    Invoke-WebRequest -Uri 'https://qagpublicdownloads.blob.core.windows.net/agent/QualysCloudAgent.exe' -OutFile 'C:\QualysCloudAgent.exe'
    Start-Process -FilePath 'C:\QualysCloudAgent.exe' -ArgumentList '/s' -Wait
    Remove-Item -Path 'C:\QualysCloudAgent.exe'
  EOF
}

