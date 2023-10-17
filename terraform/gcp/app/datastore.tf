resource "random_password" "root_password" {
  length  = 16
  special = false
}

resource "random_string" "bucket_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "google_sql_database_instance" "instance" {
  name             = "minecraft-instance"
  region           = var.location
  database_version = "POSTGRES_15"

  root_password = random_password.root_password.result

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      authorized_networks {
        name  = "public"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_database" "minecraft" {
  name            = "${var.environment}"
  instance        = google_sql_database_instance.instance.name
  deletion_policy = "ABANDON"
}