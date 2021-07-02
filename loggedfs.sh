#!/usr/bin/env bash
set -euxo pipefail

/usr/bin/loggedfs -f -p $S3FS_MOUNT_PATH | /usr/bin/sed -r -e 's#.*(release|unlink|write|open|getattr|mknod)[0-9 a-z]*([^ ]*).*(SUCCESS|FAILURE).*uid = ([0-9]*).*#printf "%s%s%s%s" $(date "+%Y-%m-%d %H:%M:%S") "\t" $(id -nu \4) "\t\1\t\2\t\3" #e' -e 't' -e 'd' >> $LOGFILE_DIR/output.log