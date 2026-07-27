provider "docker" {}

locals {
  image_name = "${var.app_name}:${var.image_tag}"

  labels = {
    "com.docker.compose.project" = var.app_name
    "managed-by"                 = "terraform"
  }
}

resource "docker_network" "app" {
  name = "${var.app_name}-net"
}

resource "docker_image" "app" {
  name = local.image_name

  build {
    context = path.module
    tag     = [local.image_name]
  }

  triggers = {
    dockerfile   = filesha256("${path.module}/Dockerfile")
    application  = filesha256("${path.module}/app.py")
    requirements = filesha256("${path.module}/requirements.txt")
  }
}

resource "docker_container" "app" {
  count = var.replicas

  name  = "${var.app_name}-${count.index}"
  image = docker_image.app.image_id

  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.app.name
  }

  ports {
    internal = var.container_port
    external = var.host_port + count.index
  }

  healthcheck {
    test     = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:${var.container_port}/healthz')"]
    interval = "30s"
    timeout  = "3s"
    retries  = 3
  }

  dynamic "labels" {
    for_each = local.labels

    content {
      label = labels.key
      value = labels.value
    }
  }
}
