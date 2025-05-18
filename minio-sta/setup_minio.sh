#!/bin/bash

# Exit on any error
set -e

# Update package list and install required packages
echo "Updating system and installing dependencies..."
apt-get update -y
apt-get install -y wget xfsprogs

# Define the drives
DRIVES=("/dev/vdb" "/dev/vdc" "/dev/vdd" "/dev/vde")
MOUNT_POINTS=("/mnt/drive1" "/mnt/drive2" "/mnt/drive3" "/mnt/drive4")

# Partition and format drives with XFS, using UUIDs
echo "Partitioning and formatting drives..."
for i in ${!DRIVES[@]}; do
  DRIVE=${DRIVES[$i]}
  MOUNT_POINT=${MOUNT_POINTS[$i]}

  # Create a single partition
  echo "Partitioning $DRIVE..."
  parted -s $DRIVE mklabel gpt
  parted -s $DRIVE mkpart primary 0% 100%

  # Format with XFS
  echo "Formatting $DRIVE1 with XFS..."
  mkfs.xfs -f ${DRIVE}1

  # Create mount point
  mkdir -p $MOUNT_POINT

  # Get UUID and add to /etc/fstab
  UUID=$(blkid -s UUID -o value ${DRIVE}1)
  echo "UUID=$UUID $MOUNT_POINT xfs defaults 0 0" >> /etc/fstab

  # Mount the drive
  mount $MOUNT_POINT
  echo "Mounted $DRIVE1 at $MOUNT_POINT with UUID $UUID"
done

# Verify mounts
echo "Verifying mounts..."
mount -a
df -h

# Install MinIO using DEB package (as recommended by MinIO)
echo "Installing MinIO..."
wget https://dl.min.io/server/minio/release/linux-amd64/minio_20250408154124.0.0_amd64.deb -O minio.deb
dpkg -i minio.deb
rm minio.deb

# Create MinIO environment file
echo "Configuring MinIO environment..."
cat <<EOF > /etc/default/minio
# MinIO root user and password
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minio-secret-key-change-me

# Specify the 4 drives using sequential notation
MINIO_VOLUMES="/mnt/drive{1...4}"

# Optional: Set console address
MINIO_OPTS="--console-address :9001"
EOF

# Set permissions for MinIO environment file
chmod 640 /etc/default/minio
chown root:minio /etc/default/minio

# Enable and start MinIO service
echo "Starting MinIO service..."
systemctl enable minio
systemctl start minio

# Check MinIO status
echo "Checking MinIO status..."
systemctl status minio --no-pager

# Display MinIO server info
echo "MinIO deployment complete. Access it at:"
echo "API: http://192.168.122.100:9000"
echo "Console: http://192.168.122.100:9001"
echo "Root User: minioadmin"
echo "Root Password: minio-secret-key-change-me"
