# Lumen Service Account Key Management - Quick Start

## 🚀 Get Started in 15 Minutes

### Prerequisites
- GCP Project Owner/Security Admin access
- `gcloud` CLI configured
- Terraform installed

### Step 1: Deploy Logging & Monitoring (5 min)

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - project_id
# - organization_id  
# - alert_email

terraform init
terraform apply
```

### Step 2: Run Initial Audit (5 min)

```bash
cd ../scripts/
./audit_sa_keys.sh YOUR_PROJECT_ID
```

Review the generated CSV for non-compliant keys.

### Step 3: Set Up Automation (5 min)

```bash
./setup_scheduler.sh YOUR_PROJECT_ID security@lumen.com
```

## ✅ What You Get

- **Real-time P1 alerts** for unauthorized key creation
- **365-day audit trail** for compliance
- **Weekly automated audits** with compliance reports
- **Incident response runbook** for security team

## 📊 Expected Results

- Detection time: **< 15 minutes**
- Compliance rate: **100%** within 30 days
- Cost: **~$60-230/month**

## 📚 Next Steps

1. Review [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md)
2. Train security team on [Incident Response Runbook](docs/INCIDENT_RESPONSE_RUNBOOK.md)
3. Schedule weekly audit report reviews

## 🆘 Need Help?

- Technical Issues: See [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md)
- Security Incidents: See [Runbook](docs/INCIDENT_RESPONSE_RUNBOOK.md)
- Questions: Contact security@lumen.com
