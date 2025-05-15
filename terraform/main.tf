/**
 * # GCP OUD Multi-Tenant LDAP Service
 * 
 * This Terraform configuration sets up the infrastructure for a multi-tenant
 * Oracle Unified Directory (OUD) service on Google Cloud Platform.
 */

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Create a GCS bucket for OUD backups
resource "google_storage_bucket" "oud_backup" {
  name          = "${var.project_id}-oud-backups"
  location      = var.region
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = var.backup_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

# Create a service account for OUD
resource "google_service_account" "oud_service_account" {
  account_id   = "oud-service-account"
  display_name = "OUD Service Account"
  description  = "Service account for OUD operations"
}

# Grant the service account access to the GCS bucket
resource "google_storage_bucket_iam_binding" "oud_backup_access" {
  bucket = google_storage_bucket.oud_backup.name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.oud_service_account.email}",
  ]
}

# Create a Secret Manager secret for OUD admin password
resource "google_secret_manager_secret" "oud_admin_password" {
  secret_id = "oud-admin-password"
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Create a Secret Manager secret for OUD replication password
resource "google_secret_manager_secret" "oud_replication_password" {
  secret_id = "oud-replication-password"
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Grant the service account access to the secrets
resource "google_secret_manager_secret_iam_binding" "oud_admin_password_access" {
  secret_id = google_secret_manager_secret.oud_admin_password.id
  role      = "roles/secretmanager.secretAccessor"
  members   = [
    "serviceAccount:${google_service_account.oud_service_account.email}",
  ]
}

resource "google_secret_manager_secret_iam_binding" "oud_replication_password_access" {
  secret_id = google_secret_manager_secret.oud_replication_password.id
  role      = "roles/secretmanager.secretAccessor"
  members   = [
    "serviceAccount:${google_service_account.oud_service_account.email}",
  ]
}

# Create a filestore instance for shared storage
resource "google_filestore_instance" "oud_nfs" {
  name     = "oud-nfs"
  tier     = "BASIC_HDD"
  location = var.zone
  
  file_shares {
    name        = "oud_data"
    capacity_gb = 1024
  }
  
  networks {
    network = "default"
    modes   = ["MODE_IPV4"]
  }
}