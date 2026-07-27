output "image" {
  description = "Fully qualified name of the image built by Terraform."
  value       = docker_image.app.name
}

output "network" {
  description = "Docker network attached to the application containers."
  value       = docker_network.app.name
}

output "endpoints" {
  description = "Host URLs for each running container instance."
  value       = [for c in docker_container.app : "http://localhost:${c.ports[0].external}"]
}
