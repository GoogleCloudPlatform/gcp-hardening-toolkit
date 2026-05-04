-- Purpose: Identify firewall rules that allow traffic from anywhere (0.0.0.0/0).
-- This helps in finding overly permissive network access.

SELECT
  name,
  asset_type,
  JSON_VALUE(resource.data, '$.network') as network,
  JSON_VALUE(resource.data, '$.direction') as direction,
  JSON_QUERY(resource.data, '$.allowed') as allowed_rules,
  JSON_QUERY(resource.data, '$.sourceRanges') as source_ranges
FROM
  `@PROJECT_ID.hardening_agent_cai_state.cai_state_*`
WHERE
  asset_type = 'compute.googleapis.com/Firewall'
  AND JSON_VALUE(resource.data, '$.direction') = 'INGRESS'
  AND REGEXP_CONTAINS(JSON_QUERY(resource.data, '$.sourceRanges'), r'"0\.0\.0\.0/0"')
ORDER BY
  name;
