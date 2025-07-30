#!/bin/bash
# etcd-backup.sh

BACKUP_DIR="/opt/etcd-backup"
BACKUP_FILE="$BACKUP_DIR/etcd-snapshot-$(date +%Y%m%d-%H%M%S).db"

# Create backup
etcdctl snapshot save $BACKUP_FILE \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Keep only last 7 days of backups
find $BACKUP_DIR -name "etcd-snapshot-*.db" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"