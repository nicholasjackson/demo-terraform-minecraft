resource "google_service_account" "worker" {
  account_id   = "boundary-worker"
  display_name = "Boundary worker service account"
}

provider "boundary" {
  addr                            = data.terraform_remote_state.hcp.outputs.boundary_cluster_url
  password_auth_method_login_name = data.terraform_remote_state.hcp.outputs.boundary_cluster_user
  password_auth_method_password   = data.terraform_remote_state.hcp.outputs.boundary_cluster_password
}

resource "boundary_worker" "controller_led" {
  scope_id    = "global"
  name        = "gcp_worker"
  description = "self managed worker with controller led auth"
}

resource "google_compute_instance" "boundary" {
  name         = "boundary-worker"
  machine_type = "e2-small"
  zone         = "${var.location}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = templatefile(
    "./scripts/init.sh",
    {
      cluster_id   =  replace(replace(data.terraform_remote_state.hcp.outputs.boundary_cluster_url,"https://",""), ".boundary.hashicorp.cloud","")
      worker_token = boundary_worker.controller_led.controller_generated_activation_token
    }
  )

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.worker.email
    scopes = ["cloud-platform"]
  }
}

output "boundary_worker_ip" {
  value = resource.google_compute_instance.boundary.network_interface[0].access_config[0].nat_ip
}
