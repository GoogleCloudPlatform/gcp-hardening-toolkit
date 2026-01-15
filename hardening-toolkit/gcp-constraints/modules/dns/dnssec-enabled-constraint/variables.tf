
variable "parent" {
  type        = string
  description = "The parent resource to attach the policy to. Must be in the format 'organizations/{organization_id}', 'folders/{folder_id}', or 'projects/{project_id}'."
}
