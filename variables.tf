variable "demo_pkg_hash" {
  type        = string
  default     = null
  description = "base64sha256 of the new zip package"
}

variable "demo_deps_hash" {
  type        = string
  default     = null
  description = "base64sha256 of the new zip package for dependencies"
}

variable "demo_events_hash" {
  type        = string
  default     = null
  description = "base64sha256 of the new zip package for the event publisher"
}

variable "demo_traffic_shift" {
  type        = number
  default     = 0.2
  description = "Percentage. Use zero for rollback."

  validation {
    condition     = var.demo_traffic_shift >= 0 && var.demo_traffic_shift <= 1
    error_message = "traffic shift percentage must be between 0 and 1"
  }
}

variable "demo_stable_version" {
  type        = string
  default     = null
  description = "defaults to the previous"
}

variable "demo_log_retention" {
  type        = number
  default     = 14
  description = "log retention in days"
}

variable "demo_environment" {
  type        = map(string)
  default     = {}
  description = "environment variables"
}
