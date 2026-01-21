variable "enforcement_toggles" {
  type        = map(bool)
  description = "Map of which policies to turn on (True/False)"
}

variable "all_constraint_names" {
  type        = map(string)
  description = "The full map of all randomized names from the definitions module"
}
variable "parent" {
  type = string # e.g., "organizations/123456"
}
