-- Purpose: Identify IAM bindings granted to external identities.
-- Replace '@ORG_DOMAIN' with your organization's domain (e.g., 'mycompany.com').

SELECT
  name as resource_name,
  asset_type,
  binding.role as role,
  member
FROM
  `@PROJECT_ID.hardening_agent_cai_state.iam_policy_*`,
  UNNEST(iam_policy.bindings) as binding,
  UNNEST(binding.members) as member
WHERE
  (STARTS_WITH(member, 'user:') OR STARTS_WITH(member, 'serviceAccount:'))
  AND NOT ENDS_WITH(member, '@ORG_DOMAIN')
ORDER BY
  member;
