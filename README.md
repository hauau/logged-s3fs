Mount s3fs and log it with loggedfs. Uids converted to usernames. 

Env:
```Shell
# Directory to watch and mount as s3fs mount
S3FS_MOUNT_PATH=/mount/dir

# Where to store logs file
LOGFILE_DIR="/mount/dir/logs"

# S3 Access
AWS_ACCESS_KEY=abc
AWS_SECRET_KEY=defg
AWS_BUCKET_REGION=eu-east-1
S3_BUCKET=bucket-1

# Misc files
S3FS_PASSWD_FILE="/etc/.passwd-s3fs-1"
S3FS_SYSTEMD_SERVICE_FILE="/etc/systemd/system/s3fs.service"
LOGGEDFS_SYSTEMD_SERVICE_FILE="/etc/systemd/system/loggedfs.service"
```

Script:
- Installs `s3fs` and `loggedfs` with apt
- Sets up `s3fs.service` and `loggedfs.service` for systemd

Caveats:
- Only some general level events are logged: (release|unlink|write|open|getattr|mknod) and other logs discarded
- Full path of log target logged only if matched by sed's `[^ ]`
