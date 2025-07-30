#!/bin/bash

# Usage: ./restore-script.sh <backup-file>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup-file>"
    echo "Available backups:"
    ls -la /opt/etcd-backup/etcd-backup-*.db
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will stop the cluster and restore from backup!"
echo "Backup file: $BACKUP_FILE"
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Stop etcd
echo "Stopping etcd..."
mv /etc/kubernetes/manifests/etcd.yaml /etc/kubernetes/etcd.yaml.backup

# Wait for etcd to stop
sleep 30

# Remove existing data
echo "Removing existing etcd data..."
rm -rf /var/lib/etcd

# Restore from backup
echo "Restoring from backup..."
etcdctl snapshot restore $BACKUP_FILE \
  --data-dir=/var/lib/etcd \
  --initial-cluster-token=etcd-cluster-1 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380 \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380

# Set ownership
chown -R etcd:etcd /var/lib/etcd

# Restart etcd
echo "Restarting etcd..."
mv /etc/kubernetes/etcd.yaml.backup /etc/kubernetes/manifests/etcd.yaml

echo "Restore completed. Please wait for cluster to be ready..."