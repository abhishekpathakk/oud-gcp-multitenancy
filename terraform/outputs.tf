/**
 * # Terraform Outputs
 * 
 * These outputs can be used by other tools or for manual operations.
 */

output "primary_cluster_name" {
  description = "The name of the primary GKE cluster"
  value       = google_container_cluster.primary.name
}

output "dr_cluster_name" {
  description = "The name of the DR GKE cluster"
  value       = google_container_cluster.dr.name
}

output "primary_cluster_endpoint" {
  description = "The endpoint for the primary GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "dr_cluster_endpoint" {
  description = "The endpoint for the DR GKE cluster"
  value       = google_container_cluster.dr.endpoint
  sensitive   = true
}

output "backup_bucket_name" {
  description = "The name of the GCS bucket for backups"
  value       = google_storage_bucket.oud_backup.name
}

output "oud_service_account_email" {
  description = "The email of the OUD service account"
  value       = google_service_account.oud_service_account.email
}

output "nfs_ip_address" {
  description = "The IP address of the NFS server"
  value       = google_filestore_instance.oud_nfs.networks[0].ip_addresses[0]
}

output "nfs_share_name" {
  description = "The name of the NFS share"
  value       = google_filestore_instance.oud_nfs.file_shares[0].name
}