# HabotConnect FZCO - Junior Cloud & DevOps Engineer Hiring Project

**Candidate:** Harshil Parmar
**Contact:** harshilparmar1907@gmil.com | +91 9824624715
**Submission date:** [DATE] &nbsp;·&nbsp; **Deadline:** 13 September 2026

This repository is a **Deployment & Automation Blueprint**. All code is written
to be validated locally and in CI. It is intentionally not applied to a live,
billing-enabled cloud project, matching the blueprint deliverable requested.

## Folder layout

```
habot-devops-blueprint/
├── README.md                              This file
├── task1_terraform_iac/                   Task 1 - Infrastructure as Code
│   ├── main.tf                            GCS D0 bucket, BigQuery D1 dataset, IAM, CMEK, Secret Manager
│   ├── variables.tf                       Typed, validated input variables
│   ├── terraform.tfvars.example           Example values (copy to terraform.tfvars)
│   ├── schema_student_onboarding.json     BigQuery table schema
│   └── rls_policy.sql                      Row-Level Security policy (applied by CI after apply)
├── task2_pokayoke_cicd/                   Task 2 - Fail-closed CI/CD gate
│   ├── .github/workflows/build_gate.yml   GitHub Actions pipeline (lint + secret scan + quarantine)
│   ├── scripts/scan_secrets.sh            Hardcoded-secret scanner (exit 1 on any hit)
│   ├── sample_bad_commit.py               Intentionally insecure file to demonstrate a failed gate
│   └── sample_good_commit.py              Clean reference file that passes every gate
├── task3_schema_dcyn/                     Task 3 - Schema mapping and validation
│   ├── serializers.py                     Django REST Framework serializer with exact limits
│   ├── dcyn_library.py                    Deterministic Yes/No rule library
│   ├── models.py                          Django ORM model with matching constraints
│   └── sample_payload.json                Example onboarding payload
└── docs/
    └── schema_mapping.xlsx                Field mapping + DCYN rules (Wrap Text enabled, full forms)
```

## How each assessment area is met

1. **Infrastructure as Code** - `main.tf` provisions the D0 raw-landing GCS
   bucket and the D1 staged BigQuery dataset with uniform access, enforced
   public-access prevention, customer-managed encryption keys, versioning, and
   lifecycle expiry.
2. **Poka-Yoke pipeline** - `build_gate.yml` fails closed. Any hardcoded
   secret, formatting error, or lint error halts the build and the quarantine
   job records the blocked commit.
3. **Data pipeline and schema validation** - the serializer enforces exact
   field limits before data reaches Pub/Sub or BigQuery, and the schema JSON
   keeps the table aligned to prevent the analytics-breaking mismatch.
4. **Identity and access control** - a dedicated least-privilege service
   account, IAM conditions scoped to a single object prefix, group-based
   dataset access, and a Row-Level Security policy.
5. **Technical rigour** - no placeholders in logic, named constants, documented
   assumptions, and every file labelled with candidate name and contact.

## Reproduce the results locally

```bash
# Task 1 - validate the Terraform (no cloud account or billing needed)
cd task1_terraform_iac
terraform fmt -check
terraform init -backend=false
terraform validate

# Task 2 - prove the gate fails closed on the bad file
cd ..
git init -q . && git add -A
bash task2_pokayoke_cicd/scripts/scan_secrets.sh   # exits 1, secret detected

# Task 3 - run the deterministic Yes/No deconstruction
cd task3_schema_dcyn
python3 dcyn_library.py sample_payload.json
```
