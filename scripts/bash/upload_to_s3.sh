#!/bin/bash

exec > >(tee /tmp/s3_upload.log|logger -t s3_upload -s 2>/dev/console) 2>&1

echo "Uploading"
echo "$TR_TORRENT_DIR/$TR_TORRENT_NAME"

S3_PATH=$(jq -r '.s3_path' /home/ubuntu/yggdrasil-master/data)

echo "s3://$S3_PATH/${TR_TORRENT_DIR:20}/$TR_TORRENT_NAME"

aws s3 sync "$TR_TORRENT_DIR/" "s3://$S3_PATH/${TR_TORRENT_DIR:20}/$TR_TORRENT_NAME" --quiet
rm -rf "$TR_TORRENT_DIR/$TR_TORRENT_NAME"

echo "Done"

