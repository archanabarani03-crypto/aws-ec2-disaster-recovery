# AWS EC2 Disaster Recovery Using Terraform

## 1. Project Overview

### Project Title
AWS EC2 Disaster Recovery and Automated Backup Using Terraform

### Objective
The objective of this project is to provision AWS infrastructure using Terraform and implement a basic disaster recovery mechanism for an EC2-hosted web application. The project uses Amazon S3 to store backups, an EC2 instance to host a web application using Nginx, and Amazon CloudWatch alarms to monitor instance status.

### Problem Statement
Applications hosted on EC2 instances can become unavailable because of instance failures, configuration problems, or accidental data loss. Without a backup and recovery procedure, restoring the application can require significant manual effort.

This project demonstrates infrastructure provisioning, automated backups, recovery from an S3 backup, basic health checks, and monitoring.

### Project Objectives
- Provision AWS resources using Terraform.
- Launch an EC2 instance to host an Nginx web application.
- Configure HTTP access through a security group.
- Create an S3 bucket to store application backups.
- Automate backup operations using a scheduled job.
- Restore available backup data from S3 during startup.
- Configure CloudWatch alarms for EC2 status failures.
- Validate the deployment and document the recovery procedure.

## 2. Architecture

```text
Administrator
     |
     v
Ubuntu Management EC2
     |
     | Terraform
     v
AWS Infrastructure
     |
     +-------------------------+
     |                         |
     v                         v
EC2 Instance               S3 Bucket
     |                     Backup Storage
     |
     +--> Nginx Web Server
     |       |
     |       +--> HTTP :80
     |       +--> /health
     |
     +--> Scheduled Backup Script
     |       |
     |       +--> Upload backup to S3
     |
     +--> Startup Recovery Script
             |
             +--> Restore available backup

CloudWatch
     |
     +--> EC2 Instance Status Alarm
     +--> EC2 System Status Alarm
```

**Note:** The S3 backup supports recovery of the data included in the backup script. It does not, by itself, guarantee complete recovery of the entire EC2 instance or all AWS resources.

## 3. AWS Services Used

| Service | Purpose |
|---|---|
| Amazon EC2 | Hosts the web application |
| Amazon S3 | Stores application backup data |
| AWS IAM | Controls permissions for AWS operations |
| Amazon CloudWatch | Monitors EC2 status and raises alarms |
| Amazon VPC | Provides network connectivity |
| Security Group | Controls inbound and outbound traffic |
| Terraform | Provisions and manages infrastructure |
| Nginx | Serves the sample website |
| Linux cron | Schedules recurring backups |

## 4. Prerequisites

Before beginning, ensure that the following are available:

1. An AWS account with permission to create the required resources.
2. An Ubuntu management EC2 instance or another machine with AWS access.
3. Terraform installed.
4. AWS CLI installed and configured.
5. Git installed.
6. A GitHub repository for version control.
7. An IAM identity with the permissions required by the Terraform configuration and the deployed application's backup and restore operations.

### Verify installed tools

```bash
terraform version
aws --version
git --version
```

### Verify AWS identity and region

```bash
aws sts get-caller-identity
aws configure get region
```

Use the intended AWS account and the configured region. This project was deployed in `ap-south-1`.

Do not commit AWS credentials, private keys, Terraform state files, or secret-containing variable files to GitHub.

## 5. Project Directory Structure

The project is organized into the following directories:

```text
aws-ec2-disaster-recovery/
├── .gitignore
├── docs/
│   └── TASK-PROCEDURE.md
├── scripts/
└── terraform/
    ├── Terraform configuration files
    └── user_data.sh.tftpl
```

The actual Terraform filenames may differ. Inspect the `terraform/` directory and use the files present in your repository.

## 6. Implementation Procedure

### Step 1: Clone or open the project

If the repository is already available on the management instance:

```bash
cd ~/aws-ec2-disaster-recovery
```

Check the project files:

```bash
ls -la
find terraform scripts docs -maxdepth 3 -type f -print
```

### Step 2: Initialize Terraform

```bash
cd ~/aws-ec2-disaster-recovery/terraform
terraform init
```

**Expected result:** Terraform initializes successfully and downloads the required providers.

### Step 3: Validate the configuration

```bash
terraform validate
```

**Expected result:**

```text
Success! The configuration is valid.
```

If validation fails, review the reported file and line number before proceeding.

### Step 4: Review the deployment plan

```bash
terraform plan -out=tfplan
```

Review the planned resource additions, modifications, and deletions.

Confirm that the plan does not unexpectedly delete the S3 backup bucket or other resources containing important data.

### Step 5: Deploy the infrastructure

After reviewing the plan:

```bash
terraform apply tfplan
```

Terraform creates or updates the resources defined in the configuration.

**Expected result:** Terraform reports that the apply operation completed successfully.

Record the EC2 instance ID, public IP address, S3 bucket name, security group ID, and CloudWatch alarm names for verification.

### Step 6: Verify the EC2 instance

In the AWS Management Console:

1. Open the EC2 dashboard.
2. Select Instances.
3. Find the instance created by the Terraform project.
4. Confirm that the instance is running.
5. Confirm that its status checks have passed.
6. Record its public IPv4 address.

You can also use the AWS CLI, provided your IAM identity has the required permissions:

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name]' \
  --output table
```

This command lists running instances visible to your AWS identity; identify the project instance using its tags or other known details.

### Step 7: Verify the web application

Open a browser and visit:

```text
http://<EC2-PUBLIC-IP>
```

Replace `<EC2-PUBLIC-IP>` with the public IP of the deployed instance.

Alternatively, run:

```bash
curl -I http://<EC2-PUBLIC-IP>
```

Check the health endpoint:

```bash
curl -i http://<EC2-PUBLIC-IP>/health
```

**Expected result:** The website responds successfully, and the configured health endpoint returns the expected response.

The security group must permit inbound TCP port 80 from the source addresses intended to access the application.

### Step 8: Understand the startup script

The EC2 startup script is stored in the Terraform user-data template.

Its intended responsibilities include:

- Installing Nginx and the required utilities.
- Installing AWS CLI v2.
- Starting Nginx and cron.
- Creating the sample website.
- Configuring a health endpoint.
- Attempting to restore available backup data from S3.
- Preparing a backup script and scheduling recurring backups.

The backup script in this project is configured to run every five minutes.

Startup restoration depends on the backup existing, the correct S3 bucket being configured, and the EC2 instance having the necessary IAM permissions. A restoration warning should be investigated rather than assumed to mean that recovery succeeded.

## 7. Backup Verification

### Step 1: Identify the configured S3 bucket

Find the bucket name in the Terraform configuration or AWS S3 console.

The bucket created during the latest deployment was:

```text
ec2-dr-lab-backup-20261019102938722600000002
```

Verify that it still exists before using this name. Resource names may differ in another deployment.

### Step 2: Inspect the backup bucket

```bash
aws s3 ls s3://<BACKUP-BUCKET-NAME>/ --recursive \
  --region ap-south-1
```

Replace the placeholder with the actual bucket name.

**Expected result:** Backup objects appear after the scheduled backup has run successfully.

If no objects appear, check the backup script, cron configuration, bucket name, and IAM permissions.

### Step 3: Verify backup and restore logs

Connect to the instance using your configured access method and inspect the relevant logs and script files.

For example:

```bash
sudo crontab -l
sudo systemctl status nginx --no-pager
sudo journalctl -u cron --no-pager -n 50
```

The exact backup script path and log file depend on the implementation.

Confirm that the script completes successfully and that the expected objects are uploaded to S3.

## 8. Disaster Recovery Procedure

This procedure demonstrates recovery of the data covered by the backup script. It is not a substitute for a tested full-instance recovery process.

### Step 1: Confirm the failure

Check:

- EC2 instance state.
- EC2 status checks.
- Website availability.
- Nginx service health.
- CloudWatch alarm state.
- Availability of recent S3 backup objects.

### Step 2: Inspect the backup

List the available backup objects:

```bash
aws s3 ls s3://<BACKUP-BUCKET-NAME>/ --recursive \
  --region ap-south-1
```

Identify a valid backup and confirm that it contains the required application data.

### Step 3: Restore the application data

The startup script attempts to restore the available backup from S3.

For a manual recovery, follow the actual restore script and configuration in the repository. Confirm the intended destination and backup format before extracting or replacing files.

Do not blindly overwrite application files or extract an unverified archive.

### Step 4: Restart and validate the application

After restoration, check Nginx:

```bash
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx --no-pager
```

Test the local application:

```bash
curl -I http://127.0.0.1/
curl -i http://127.0.0.1/health
```

Then test the public endpoint from an authorized client.

### Step 5: Confirm recovery

Record:

- Time the failure was detected.
- Backup selected for recovery.
- Time recovery started and completed.
- Whether the website and health endpoint work.
- Any data missing since the last successful backup.
- Any manual actions required.

The maximum potential data loss depends on the last successful backup, not simply on the configured five-minute schedule.

## 9. CloudWatch Monitoring

The project configures two alarms:

```text
ec2-dr-lab-instance-status-failed
ec2-dr-lab-system-status-failed
```

These monitor EC2 instance status and system status, respectively.

### Verification procedure

1. Open the Amazon CloudWatch console.
2. Navigate to Alarms.
3. Search for the alarm names.
4. Confirm the correct instance and metric are configured.
5. Review the alarm state and recent metric history.

A status alarm may remain in `INSUFFICIENT_DATA` until sufficient metric data is available. This is not necessarily an application failure.

Alarm configuration and state do not, on their own, prove that the web application is healthy. Check the website and health endpoint separately.

## 10. Troubleshooting

| Problem | Possible cause | Recommended action |
|---|---|---|
| Terraform reports `UnauthorizedOperation` | Insufficient IAM permissions | Review the denied API action and update the appropriate IAM policy |
| Terraform cannot read VPC attributes | Missing VPC read permissions | Allow the required `ec2:DescribeVpcAttribute` action |
| Website is unavailable | Instance, Nginx, networking, or startup failure | Check EC2 status checks, Nginx status, user-data logs, and security group rules |
| Port 80 is unreachable | Incorrect security group or routing | Verify inbound TCP 80, public IP, route table, and subnet configuration |
| Backup bucket is empty | Cron failure, script error, or permissions issue | Inspect cron, script output, S3 bucket name, and IAM permissions |
| S3 upload fails | Missing S3 permissions or incorrect bucket | Verify the instance role and required bucket/object permissions |
| Restore fails | No valid backup or incorrect restore configuration | Inspect backup objects, restore logs, and the restore script |
| CloudWatch alarm has insufficient data | Metrics have not populated or configuration is incorrect | Check the metric, instance ID, period, and evaluation settings |
| AWS CLI is unavailable during startup | Installation failure or incorrect installation method | Review cloud-init logs and verify AWS CLI v2 installation |
| Git push fails | SSH key or repository permission issue | Test `ssh -T git@github.com` and verify the repository remote |

### Useful diagnostic commands

Inspect user-data and cloud-init output:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
sudo cloud-init status --long
```

Inspect Nginx:

```bash
sudo systemctl status nginx --no-pager
sudo nginx -t
sudo tail -n 100 /var/log/nginx/error.log
```

Inspect cron and recent system messages:

```bash
sudo journalctl -u cron --no-pager -n 100
sudo journalctl -p warning --no-pager -n 100
```

## 11. Security Considerations

- Use an EC2 IAM role rather than embedding AWS access keys in scripts.
- Apply least-privilege permissions for the required S3 bucket and CloudWatch operations.
- Restrict SSH access to trusted IP addresses if SSH is enabled.
- Restrict public HTTP access where the application does not need to be publicly accessible.
- Enable S3 Block Public Access and use appropriate bucket policies.
- Consider S3 versioning and lifecycle policies for backup retention.
- Protect Terraform state because it may contain sensitive values.
- Never commit private keys, AWS credentials, tokens, or sensitive `.tfvars` files to GitHub.
- Test restoration in a controlled environment before relying on it for production recovery.

## 12. GitHub Repository Procedure

### Step 1: Check the repository

```bash
cd ~/aws-ec2-disaster-recovery
git status
git remote -v
```

### Step 2: Add the documentation

This document should be saved as:

```text
docs/TASK-PROCEDURE.md
```

### Step 3: Review files before committing

```bash
git status
git diff --check
git diff --cached
```

If the file is not yet staged, `git diff --cached` may be empty. Stage the intended files before reviewing the staged changes.

### Step 4: Commit the task procedure

```bash
git add docs/TASK-PROCEDURE.md
git commit -m "Add AWS EC2 disaster recovery task procedure"
```

### Step 5: Push to GitHub

```bash
git push origin main
```

Open the GitHub repository and verify that `docs/TASK-PROCEDURE.md` is visible.

Repository:

https://github.com/archanabarani03-crypto/aws-ec2-disaster-recovery

## 13. Cleanup Procedure

**Warning:** Cleanup can permanently delete resources and data. Confirm that the backup data is no longer required before destroying any infrastructure.

First inspect the Terraform plan:

```bash
cd ~/aws-ec2-disaster-recovery/terraform
terraform plan -destroy
```

If you intentionally want to remove
