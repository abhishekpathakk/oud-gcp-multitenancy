# Multi-Tenant LDAP-as-a-Service on GCP (OUD Lite Version)

This project implements a production-ready Oracle Unified Directory (OUD) service on Google Cloud Platform with multi-tenancy support, automated backups, and disaster recovery capabilities.

## 🧱 Project Summary

- Deploy a production-like OUD directory service on GCP
- Support multi-tenant suffixes for organizational isolation
- Implement daily backups to Google Cloud Storage (GCS)
- Provide restore logic to DR cluster in separate region

## 🔧 Tech Stack

| Layer | Tools |
|-------|-------|
| Infra Provisioning | Terraform |
| Config Management | Ansible |
| App Deployment | Helm + Kubernetes |
| Storage | GCS |
| DR Setup | CronJob + NFS + Terraform |
| Secrets | Secret Manager |
| Monitoring | Stackdriver (Log-based alert) |

## 🛠️ Architecture Overview

```
       +---------------------------+
       |     GCP Project (IAM)     |
       +---------------------------+
                  |
                  ▼
         +------------------+
         |  GKE Cluster PR   |
         +------------------+
         |  Namespace: ldap  |
         |  OUD StatefulSet  |
         |  NFS Mount + PVC  |
         +--------+---------+
                  |
            Backup Script
                  |
                  ▼
         +------------------+
         |  GCS Bucket (PR) |
         +------------------+
                  |
       (Manual or Auto Restore)
                  ▼
         +------------------+
         |  GKE Cluster DR   |
         |  Namespace: ldap  |
         |  Restore Pod      |
         +------------------+
```

## 📂 Project Structure

```
gcp-oud-mini/
├── terraform/
│   ├── main.tf           # Provider configuration and main resources
│   ├── gke.tf            # GKE cluster configuration
│   ├── outputs.tf        # Output variables for use in other tools
├── helm/
│   └── charts/oud/
│       ├── templates/    # Kubernetes manifests templates
│       ├── values.yaml   # Default configuration values
├── ansible/
│   └── playbooks/
│       ├── enable-replication.yml  # Configure OUD replication
│       ├── backup-oud.yml          # Backup procedures
│       └── restore-oud.yml         # Restore procedures
├── cronjobs/
│   └── daily-backup.yaml  # Kubernetes CronJob for automated backups
├── mop/
│   └── DR-restore.md      # Manual operation procedures for DR
└── README.md              # Project documentation
```

## 🎯 Key Features

| Feature | Implementation |
|---------|----------------|
| GKE Cluster | Terraform (google_container_cluster) |
| OUD Deployment | Helm StatefulSet chart |
| Namespace per tenant | Values override (tenant_id) |
| Suffix Creation | Ansible playbook with ldapmodify |
| Daily Backup to GCS | Kubernetes CronJob + ldapsearch |
| Restore Script | Bash or Ansible |
| DR Cluster Setup | Terraform DR module |
| Monitoring | Stackdriver + log-based alert if backup fails |

## 🧠 Bonus Features

- Integrate with GitHub Actions for CI/CD
- Secret rotation via GCP Secret Manager
- Stackdriver dashboard showing backup success/failure
- Slack alert for failed cron

## 🚀 Getting Started

1. Set up GCP credentials
2. Run Terraform to provision infrastructure
3. Deploy OUD using Helm
4. Configure tenants using Ansible playbooks
5. Verify backup and restore procedures

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.