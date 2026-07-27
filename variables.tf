variable "app_name" {
  description = "Base name applied to the image, container and network."
  type        = string
  default     = "devops-app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.app_name))
    error_message = "app_name must be lowercase alphanumeric with hyphens, 3-31 characters."
  }
}

variable "image_tag" {
  description = "Tag applied to the locally built image."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the application listens on inside the container."
  type        = number
  default     = 5000
}

variable "host_port" {
  description = "Port published on the Docker host."
  type        = number
  default     = 8080
}

variable "replicas" {
  description = "Number of container instances to run."
  type        = number
  default     = 1

  validation {
    condition     = var.replicas >= 1 && var.replicas <= 5
    error_message = "replicas must be between 1 and 5."
  }
}
