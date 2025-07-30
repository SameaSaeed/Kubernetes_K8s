#!/bin/bash

# Set variables
BACKUP_DIR="/opt/etcd-backup"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/etcd-backup-${BACKUP_DATE}.db"
RETENTION_DAYS=7

# etcd connection details
export ETCDCTL_API=3
ETCD_ENDPOINT="https://127.0.0.1:2379"
ETCD_CACERT="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_CERT="/etc/kubernetes/pki/etcd/server.crt"
ETCD_KEY="/etc/kubernetes/pki/etcd/server.key"

# Create backup
echo "Creating backup: $BACKUP_FILE"
etcdctl snapshot save $BACKUP_FILE \
  --endpoints=$ETCD_ENDPOINT \
  --cacert=$ETCD_CACERT \
  --cert=$ETCD_CERT \
  --key=$ETCD_KEY

# Verify backup
if etcdctl snapshot status $BACKUP_FILE > /dev/null 2>&1; then
    echo "Backup created successfully: $BACKUP_FILE"
else
    echo "Backup verification failed!"
    exit 1
fi

# Clean old backups
find $BACKUP_DIR -name "etcd-backup-*.db" -mtime +$RETENTION_DAYS -delete
echo "Cleaned backups older than $RETENTION_DAYS days"

echo "Backup process completed successfully"