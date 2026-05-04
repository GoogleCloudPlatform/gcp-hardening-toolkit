-- Purpose: List service accounts that have user-managed keys.
-- User-managed keys pose a security risk if not rotated regularly.

SELECT
  name,
  asset_type,
  JSON_VALUE(resource.data, '$.keyType') as key_type,
  JSON_VALUE(resource.data, '$.validAfterTime') as valid_after,
  JSON_VALUE(resource.data, '$.validBeforeTime') as valid_before
FROM
  `@PROJECT_ID.hardening_agent_cai_state.cai_state_*`
WHERE
  asset_type = 'iam.googleapis.com/ServiceAccountKey'
  AND JSON_VALUE(resource.data, '$.keyType') = 'USER_MANAGED'
ORDER BY
  name;
