-- =============================================================================
-- Task 1 - Row-Level Security (RLS) policy for D1 student_onboarding table.
-- Author: Harshil Parmar | Contact: harshilparmar1907@gmil.com | +91 9824624715
--
-- BigQuery Row Access Policies are applied via DDL (there is no first-class
-- Terraform resource for a row access policy). This file is applied by the
-- CI pipeline immediately after `terraform apply`, keeping the security rule
-- in version control and out of human hands (Poka-Yoke).
--
-- Rule: an analyst may only see rows whose region_owner_group matches a group
-- they belong to. This enforces data isolation between regional teams.
-- =============================================================================

CREATE ROW ACCESS POLICY region_isolation_policy
ON `PROJECT_ID.habot_staging_d1_staged_enforced.student_onboarding`
GRANT TO ('group:analysts@habot.io')
FILTER USING (
  region_owner_group IN (
    SELECT region_owner_group
    FROM `PROJECT_ID.habot_staging_d1_staged_enforced.analyst_region_map`
    WHERE analyst_email = SESSION_USER()
  )
);
