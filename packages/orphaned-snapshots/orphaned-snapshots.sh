#!/usr/bin/env bash

delete_snapshots() {
  for snapshot_id in $ORPHANED_SNAPSHOT_IDS; do
    echo "aws ec2 delete-snapshot --snapshot-id $snapshot_id"
    aws ec2 delete-snapshot --snapshot-id "$snapshot_id"
  done
}

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# To get the list of snapshots not linked to any volume.
ORPHANED_SNAPSHOT_IDS=$(comm -23 <(aws ec2 describe-snapshots --owner-ids "$AWS_ACCOUNT_ID" \
  --query 'Snapshots[*].SnapshotId' --output text |
  tr '\t' '\n' | sort) <(aws ec2 describe-volumes \
    --query 'Volumes[*].SnapshotId' --output text | tr '\t' '\n' | sort | uniq))

delete_snapshots

# To get the list of snapshots not linked to any AMIs.
ORPHANED_SNAPSHOT_IDS=$(comm -23 <(aws ec2 describe-snapshots --owner-ids "$AWS_ACCOUNT_ID" \
  --query 'Snapshots[*].SnapshotId' --output text |
  tr '\t' '\n' | sort) <(aws ec2 describe-images \
    --filters Name=state,Values=available --owners "$AWS_ACCOUNT_ID" \
    --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId" --output text | tr '\t' '\n' | sort | uniq))

delete_snapshots
