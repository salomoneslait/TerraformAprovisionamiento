provider "google" {
  credentials = file("${var.credentials-path}")
  project     = "${var.project}"
  region      = "us-east1"
  zone        = "us-east1-b"
}

resource "google_compute_network" "vpc-network" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "my-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  network                  = google_compute_network.vpc-network.self_link
  region                   = var.region
  private_ip_google_access = false
}

resource "google_compute_router" "router" {
  name    = "mi-router"
  region  = var.region
  network = google_compute_network.vpc-network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                   = "my-nat"
  router                 = google_compute_router.router.name
  region                 = google_compute_router.router.region
  nat_ip_allocate_option = "AUTO_ONLY"
  # source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "firewall-rule" {
  name          = "ssh-rule"
  network       = google_compute_network.vpc-network.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["ssh"]
}

resource "google_compute_instance" "linux-machine" {
  
  name                      = "my-linux-vm"
  zone                      = "us-east1-b"
  tags                      = ["ssh"]
  can_ip_forward            = true
  machine_type              = "e2-medium"
  allow_stopping_for_update = true

  boot_disk {

    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    # access_config {}
  }

  service_account {
    email  = google_service_account.linux-instance-sa.email
    #scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

}

resource "google_service_account" "linux-instance-sa" {
  project = var.project
  account_id   = "linux-instance-sa-2"
  display_name = "linux Instance Service Account"
}

resource "google_project_iam_custom_role" "my-role" {
  role_id     = "myrole"
  title       = "My Role"
  description = "Custom role for my service account"
  permissions = [
    "storage.buckets.list"
  ]
}

resource "google_project_iam_binding" "my-service-account-binding" {
  project = var.project
  role    = google_project_iam_custom_role.my-role.id
  members = [
    "serviceAccount:${google_service_account.linux-instance-sa.email}",
  ]
}