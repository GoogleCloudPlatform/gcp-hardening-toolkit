-- Purpose: Identify Compute Engine instances with disks not using Customer-Managed Encryption Keys (CMEK).
-- CMEK provides better control over data encryption.

SELECT
  name,
  asset_type,
  JSON_VALUE(disk, '$.deviceName') as device_name,
  JSON_VALUE(disk, '$.diskEncryptionKey.kmsKeyName') as kms_key_name
FROM
  `@PROJECT_ID.hardening_agent_cai_state.cai_state_*`,
  UNNEST(JSON_EXTRACT_ARRAY(resource.data, '$.disks')) as disk
WHERE
  asset_type = 'compute.googleapis.com/Instance'
  AND (JSON_VALUE(disk, '$.diskEncryptionKey.kmsKeyName') IS NULL
       OR JSON_VALUE(disk, '$.diskEncryptionKey.kmsKeyName') = '')
ORDER BY
  name;
