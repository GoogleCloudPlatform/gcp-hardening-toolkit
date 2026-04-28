-- Purpose: Identify users or service accounts with primitive roles (Owner, Editor).
-- Primitive roles are broad and should be avoided in favor of predefined roles.

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
  binding.role IN ('roles/owner', 'roles/editor')
ORDER BY
  role, member;
