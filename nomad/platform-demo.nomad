job "platform-demo" {

  datacenters = ["dc1"]

  type = "service"

  group "app" {

    network {
      mode = "host"

      port "http" {
        static = 8080
      }
    }

    service {
      name     = "platform-demo"
      provider = "consul"
      port     = "http"

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "app" {

      driver = "docker"

      config {
        image        = "${IMAGE}"
        network_mode = "host"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
