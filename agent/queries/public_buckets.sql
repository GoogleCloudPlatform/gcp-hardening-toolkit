-- Purpose: Identify Cloud Storage buckets with public access.
-- Public buckets pose a high risk of data leakage.

SELECT
  name as bucket_name,
  asset_type,
  binding.role as role,
  member
FROM
  `@PROJECT_ID.hardening_agent_cai_state.iam_policy_*`,
  UNNEST(iam_policy.bindings) as binding,
  UNNEST(binding.members) as member
WHERE
  asset_type = 'storage.googleapis.com/Bucket'
  AND member IN ('allUsers', 'allAuthenticatedUsers')
ORDER BY
  bucket_name;
