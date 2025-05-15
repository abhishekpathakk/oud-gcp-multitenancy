/**
 * # Variables for OUD Multi-Tenant LDAP Service
 */

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for primary resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for primary resources"
  type        = string
  default     = "us-central1-a"
}

variable "dr_region" {
  description = "The GCP region for DR resources"
  type        = string
  default     = "us-west1"
}

variable "dr_zone" {
  description = "The GCP zone for DR resources"
  type        = string
  default     = "us-west1-a"
}

variable "node_count" {
  description = "Number of nodes in the primary GKE cluster"
  type        = number
  default     = 3
}

variable "dr_node_count" {
  description = "Number of nodes in the DR GKE cluster"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for primary GKE nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "dr_machine_type" {
  description = "Machine type for DR GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}