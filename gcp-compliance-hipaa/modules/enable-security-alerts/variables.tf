variable "project_id" {
  description = "The project ID to deploy the security alerts to."
  type        = string
}

variable "notification_email" {
  description = "The email address for security alert notifications."
  type        = string
}

variable "notification_threshold" {
  description = "The threshold for the DDoS alert."
  type        = number
  default     = 100
}
