# =============================================================================
# HabotConnect FZCO - Junior Cloud & DevOps Engineer Hiring Project
# Task 1: Terraform Secure Staging Provisioning (Infrastructure as Code)
#
# Author : Harshil Parmar
# Contact : harshilparmar1907@gmil.com | +91 9824624715
# Date   : [SUBMISSION DATE]
#
# Purpose:
#   Securely provision the two-tier staging data platform.
#     D0 (Raw Landing)    -> Google Cloud Storage bucket for untrusted raw input.
#     D1 (Staged/Enforced)-> BigQuery dataset with enforced access controls.
#   The configuration remediates the reported incident (unencrypted API
#   credentials left in raw application code) by moving every secret into
#   Google Secret Manager and by denying all public and broad access paths.
#
# NOTE ON EXECUTION:
#   This is a validated blueprint. It passes `terraform init -backend=false`
#   and `terraform validate`. It is intentionally NOT applied against a live
#   billing-enabled GCP project, in line with the "blueprint" deliverable.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------------------------------------------------
# Customer-managed encryption key (CMEK)
# Golden Rule: data at rest is encrypted with a key we control and rotate,
# never with a default Google-managed key alone.
# -----------------------------------------------------------------------------
resource "google_kms_key_ring" "staging_ring" {
  name     = "${var.name_prefix}-staging-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "staging_key" {
  name            = "${var.name_prefix}-staging-key"
  key_ring        = google_kms_key_ring.staging_ring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# Grant the Cloud Storage and BigQuery service agents permission to use the key.
resource "google_kms_crypto_key_iam_member" "gcs_key_user" {
  crypto_key_id = google_kms_crypto_key.staging_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "bq_key_user" {
  crypto_key_id = google_kms_crypto_key.staging_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${var.project_number}@bigquery-encryption.iam.gserviceaccount.com"
}

# -----------------------------------------------------------------------------
# D0 - Raw Landing bucket (Google Cloud Storage)
# Fail-closed defaults: public access blocked, uniform access, versioned,
# CMEK-encrypted, and auto-expiring so raw untrusted data never lingers.
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "d0_raw_landing" {
  name                        = "${var.name_prefix}-d0-raw-landing"
  location                    = var.region
  storage_class               = "STANDARD"
  force_destroy               = false
  uniform_bucket_level_access = true            # no per-object ACLs
  public_access_prevention    = "enforced"      # block all public exposure

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.staging_key.id
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    tier        = "d0-raw-landing"
    environment = "staging"
    managed_by  = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Dedicated least-privilege service account for the ingestion pipeline.
# It is the ONLY identity allowed to write raw objects into D0.
# -----------------------------------------------------------------------------
resource "google_service_account" "ingest_sa" {
  account_id   = "${var.name_prefix}-ingest-sa"
  display_name = "Staging raw-landing ingestion service account"
}

# -----------------------------------------------------------------------------
# IAM with conditions (Least Privilege + Golden Rule enforcement)
# The ingestion account may only create objects (not read, not delete) and
# only inside the D0 bucket. The IAM Condition further scopes the grant to
# object paths under the "incoming/" prefix.
# -----------------------------------------------------------------------------
resource "google_storage_bucket_iam_member" "ingest_writer_conditional" {
  bucket = google_storage_bucket.d0_raw_landing.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.ingest_sa.email}"

  condition {
    title       = "restrict-to-incoming-prefix"
    description = "Ingestion account may only write objects under the incoming/ prefix."
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.name_prefix}-d0-raw-landing/objects/incoming/\")"
  }
}

# -----------------------------------------------------------------------------
# D1 - Staged / Enforced dataset (BigQuery)
# CMEK-encrypted. Access is granted explicitly and narrowly; no allAuthenticated
# or allUsers members are ever permitted.
# -----------------------------------------------------------------------------
resource "google_bigquery_dataset" "d1_staged_enforced" {
  dataset_id                  = "${replace(var.name_prefix, "-", "_")}_d1_staged_enforced"
  friendly_name               = "D1 Staged Enforced"
  description                 = "Validated, schema-enforced staging data promoted from D0 raw landing."
  location                    = var.region
  default_table_expiration_ms = 5184000000 # 60 days

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.staging_key.id
  }

  # Explicit access block - owner is a group, not a personal account.
  access {
    role          = "OWNER"
    group_by_email = var.data_owner_group
  }

  access {
    role          = "READER"
    group_by_email = var.analyst_reader_group
  }

  labels = {
    tier        = "d1-staged-enforced"
    environment = "staging"
    managed_by  = "terraform"
  }
}

# Enforced-schema table that receives promoted student onboarding records.
resource "google_bigquery_table" "student_onboarding" {
  dataset_id          = google_bigquery_dataset.d1_staged_enforced.dataset_id
  table_id            = "student_onboarding"
  deletion_protection = true

  schema = file("${path.module}/schema_student_onboarding.json")

  labels = {
    tier       = "d1-staged-enforced"
    managed_by = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Secret Manager - the fix for the leaked API credentials.
# The credential value is NOT stored in Terraform state or code; the secret
# container is provisioned here and the version is added out-of-band by an
# operator or the CI vault step.
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "downstream_api_key" {
  secret_id = "${var.name_prefix}-downstream-api-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    environment = "staging"
    managed_by  = "terraform"
  }
}

# Only the ingestion service account may read the secret at runtime.
resource "google_secret_manager_secret_iam_member" "ingest_secret_accessor" {
  secret_id = google_secret_manager_secret.downstream_api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ingest_sa.email}"
}
