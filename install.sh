#!/usr/bin/env bash
set -euxo pipefail

# --- Config ---

set -a
source .env
set +a

# --- END Config ---

# Require root
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

# Stop services
systemctl stop s3fs || true
systemctl stop loggedfs || true

# Create dir if doesn't exist
echo "Creating dir $S3FS_MOUNT_PATH"
mkdir -p $S3FS_MOUNT_PATH
echo "Creating dir $LOGFILE_DIR"
mkdir -p $LOGFILE_DIR

# Install dependencies
apt-get update  # To get the latest package lists
apt-get install loggedfs s3fs -y 

# Write s3fs config
echo "Writing s3fs config to $S3FS_PASSWD_FILE"
echo "$AWS_ACCESS_KEY:$AWS_SECRET_KEY" > $S3FS_PASSWD_FILE
chmod 0600 $S3FS_PASSWD_FILE

# Copy loggedfs script
cp loggedfs.sh /usr/bin/loggedfs.sh
chmod +x /usr/bin/loggedfs.sh

# Write S3FS systemd unit
echo "Creating $S3FS_SYSTEMD_SERVICE_FILE"
echo "[Unit]
Description=s3fs mount
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/s3fs ${S3_BUCKET} ${S3FS_MOUNT_PATH} -o passwd_file=${S3FS_PASSWD_FILE},endpoint=${AWS_BUCKET_REGION} -o allow_other -o umask=0000
ExecStop=/bin/fusermount -u ${S3FS_MOUNT_PATH}

[Install]
WantedBy=multi-user.target
" > $S3FS_SYSTEMD_SERVICE_FILE

# Write LoggedFS systemd unit
echo "Creating $LOGGEDFS_SYSTEMD_SERVICE_FILE"
echo "[Unit]
Description=LoggedFS watching s3fs mount
Wants=multi-user.target
After=multi-user.target

[Service]
Type=simple
RemainAfterExit=no
ExecStart=/usr/bin/loggedfs.sh
Environment=S3FS_MOUNT_PATH=$S3FS_MOUNT_PATH
Environment=LOGFILE_DIR=$LOGFILE_DIR

[Install]
WantedBy=multi-user.target
" > $LOGGEDFS_SYSTEMD_SERVICE_FILE

# Write logrotate conf
echo "$LOGFILE_DIR/*.log {
    weekly
    missingok
    rotate 10
    size 10M
    dateext
    dateformat -%Y%m%d
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        systemctl restart loggedfs
    endscript
}
" > /etc/logrotate.d/loggeds3fs

# Starting services
systemctl daemon-reload
systemctl enable loggedfs
systemctl enable s3fs
systemctl start s3fs
systemctl start loggedfs

echo "Done."
