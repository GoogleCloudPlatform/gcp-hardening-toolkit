-- Purpose: Identify static external IP addresses that are not attached to any resource.
-- Orphaned IPs waste money and can be used for unauthorized activities if not monitored.

SELECT
  name,
  asset_type,
  JSON_VALUE(resource.data, '$.address') as ip_address,
  JSON_VALUE(resource.data, '$.status') as status,
  JSON_VALUE(resource.data, '$.addressType') as address_type
FROM
  `@PROJECT_ID.hardening_agent_cai_state.cai_state_*`
WHERE
  asset_type = 'compute.googleapis.com/Address'
  AND JSON_VALUE(resource.data, '$.addressType') = 'EXTERNAL'
  AND JSON_VALUE(resource.data, '$.status') = 'RESERVED'
ORDER BY
  name;
