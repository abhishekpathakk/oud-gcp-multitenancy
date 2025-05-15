# Disaster Recovery Restore Procedure

This document outlines the step-by-step procedure for restoring the OUD service in a disaster recovery scenario.

## Prerequisites

- Access to GCP console and gcloud CLI
- kubectl configured to access both primary and DR GKE clusters
- Ansible installed on the operator's machine
- Latest backup available in GCS bucket

## Restore Procedure

### 1. Assess the Situation

1. Verify that the primary cluster is indeed unavailable:
   ```bash
   kubectl --context=primary get nodes
   kubectl --context=primary get pods -n ldap
   ```

2. Check the status of the DR cluster:
   ```bash
   kubectl --context=dr get nodes
   kubectl --context=dr get pods -n ldap
   ```

### 2. Prepare the DR Environment

1. Switch kubectl context to the DR cluster:
   ```bash
   kubectl config use-context dr
   ```

2. Ensure the OUD namespace exists:
   ```bash
   kubectl create namespace ldap --dry-run=client -o yaml | kubectl apply -f -
   ```

3. Create required secrets in the DR cluster:
   ```bash
   # Get secrets from Secret Manager
   OUD_ADMIN_PASSWORD=$(gcloud secrets versions access latest --secret=oud-admin-password)
   OUD_REPLICATION_PASSWORD=$(gcloud secrets versions access latest --secret=oud-replication-password)
   
   # Create Kubernetes secrets
   kubectl -n ldap create secret generic oud-admin-password --from-literal=password=$OUD_ADMIN_PASSWORD
   kubectl -n ldap create secret generic oud-replication-password --from-literal=password=$OUD_REPLICATION_PASSWORD
   ```

### 3. Deploy OUD in DR Cluster

1. Deploy OUD using Helm:
   ```bash
   helm upgrade --install oud ./helm/charts/oud \
     --namespace ldap \
     --set replicaCount=2 \
     --set nfs.server=$(terraform output -raw dr_nfs_ip_address) \
     --set backup.bucketName=$(terraform output -raw backup_bucket_name)
   ```

2. Wait for the OUD pods to be in Running state:
   ```bash
   kubectl -n ldap wait --for=condition=Ready pod/oud-oud-0 --timeout=300s
   ```

### 4. Restore Data from Backup

1. List available backups:
   ```bash
   gsutil ls -l gs://$(terraform output -raw backup_bucket_name)/backups/ | sort -k 2
   ```

2. Choose the most recent backup file (e.g., `oud-backup-20230615-010000.tar.gz`)

3. Run the restore Ansible playbook:
   ```bash
   export GCS_BUCKET_NAME=$(terraform output -raw backup_bucket_name)
   ansible-playbook ansible/playbooks/restore-oud.yml -e "backup_file=oud-backup-20230615-010000.tar.gz"
   ```

### 5. Verify the Restore

1. Check if OUD is operational:
   ```bash
   kubectl -n ldap exec oud-oud-0 -- ldapsearch -h localhost -p 1389 \
     -D "cn=Directory Manager" -w "$OUD_ADMIN_PASSWORD" \
     -b "" -s base "objectclass=*"
   ```

2. Verify tenant data:
   ```bash
   # For each tenant suffix (e.g., dc=tenant1,dc=com)
   kubectl -n ldap exec oud-oud-0 -- ldapsearch -h localhost -p 1389 \
     -D "cn=Directory Manager" -w "$OUD_ADMIN_PASSWORD" \
     -b "dc=tenant1,dc=com" -s base "objectclass=*"
   ```

### 6. Enable Replication in DR Cluster

1. Run the replication Ansible playbook for each tenant suffix:
   ```bash
   ansible-playbook ansible/playbooks/enable-replication.yml -e "base_dn=dc=tenant1,dc=com"
   ```

### 7. Update DNS/Load Balancer

1. Update DNS records or load balancer configuration to point to the DR cluster's OUD service.

### 8. Configure Backup in DR Cluster

1. Apply the backup CronJob:
   ```bash
   kubectl -n ldap apply -f cronjobs/daily-backup.yaml
   ```

2. Create the ConfigMap for backup configuration:
   ```bash
   kubectl -n ldap create configmap oud-backup-config \
     --from-literal=gcs_bucket_name=$(terraform output -raw backup_bucket_name) \
     --from-literal=tenant_suffixes="dc=tenant1,dc=com dc=tenant2,dc=com"
   ```

## Failback Procedure (When Primary Cluster is Available Again)

1. Deploy OUD in the primary cluster
2. Restore the latest backup from DR to primary
3. Enable replication from DR to primary
4. Switch traffic back to primary
5. Disable and remove OUD from DR cluster

## Troubleshooting

### Common Issues

1. **Restore fails with LDAP errors**:
   - Check if the target suffix exists
   - Verify that the admin password is correct
   - Examine the LDIF file for any syntax errors

2. **Replication fails to initialize**:
   - Ensure all OUD instances are running
   - Verify network connectivity between pods
   - Check that the replication admin user exists

3. **Backup not found in GCS**:
   - Verify the bucket name is correct
   - Check if the backup job ran successfully
   - Ensure the service account has proper permissions

### Getting Help

