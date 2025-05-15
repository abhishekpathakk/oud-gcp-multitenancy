/**
 * # GKE Cluster Configuration
 * 
 * This file defines the GKE clusters for both primary and DR environments.
 */

# Primary GKE cluster
resource "google_container_cluster" "primary" {
  name     = "oud-primary-cluster"
  location = var.zone
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }
  
  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Primary node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "oud-primary-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = false
    machine_type = var.machine_type
    
    # Google recommends custom service accounts with minimal permissions
    service_account = google_service_account.oud_service_account.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # Enable workload identity on the node pool
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# DR GKE cluster (in a different region)
resource "google_container_cluster" "dr" {
  name     = "oud-dr-cluster"
  location = var.dr_zone
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }
  
  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# DR node pool
resource "google_container_node_pool" "dr_nodes" {
  name       = "oud-dr-node-pool"
  location   = var.dr_zone
  cluster    = google_container_cluster.dr.name
  node_count = var.dr_node_count

  node_config {
    preemptible  = false
    machine_type = var.dr_machine_type
    
    service_account = google_service_account.oud_service_account.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}