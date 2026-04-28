-- Purpose: Understand VPC Service Control perimeters and protected resources.
-- This helps in identifying network dependencies and security boundaries.

SELECT
  name,
  asset_type,
  JSON_VALUE(resource.data, '$.title') as perimeter_name,
  JSON_VALUE(resource.data, '$.perimeterType') as perimeter_type,
  JSON_QUERY(resource.data, '$.status.resources') as protected_resources,
  JSON_QUERY(resource.data, '$.status.restrictedServices') as restricted_services
FROM
  `@PROJECT_ID.hardening_agent_cai_state.cai_state_*`
WHERE
  asset_type = 'accesscontextmanager.googleapis.com/ServicePerimeter'
ORDER BY
  name;
