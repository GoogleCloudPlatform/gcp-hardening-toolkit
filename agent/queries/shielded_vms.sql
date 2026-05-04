-- Purpose: Identify Compute Engine instances with Shielded VM features disabled.
-- Shielded VMs provide verifiable integrity and are a security best practice.

SELECT
  name,
  asset_type,
  JSON_VALUE(resource.data, '$.shieldedInstanceConfig.enableSecureBoot') as enable_secure_boot,
  JSON_VALUE(resource.data, '$.shieldedInstanceConfig.enableVtpm') as enable_vtpm,
  JSON_VALUE(resource.data, '$.shieldedInstanceConfig.enableIntegrityMonitoring') as enable_integrity_monitoring
FROM
  `@PROJECT_ID.hardening_agent_cai_state.cai_state_*`
WHERE
  asset_type = 'compute.googleapis.com/Instance'
  AND (
    JSON_VALUE(resource.data, '$.shieldedInstanceConfig.enableSecureBoot') = 'false'
    OR JSON_VALUE(resource.data, '$.shieldedInstanceConfig.enableVtpm') = 'false'
    OR JSON_VALUE(resource.data, '$.shieldedInstanceConfig.enableIntegrityMonitoring') = 'false'
  )
ORDER BY
  name;
