terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
}

resource "yandex_compute_instance" "router" {
  name        = "router"
  platform_id = "standard-v1"
  zone        = "ru-central1-b"
  hostname    = "router"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd811ke2vnjc423tj8ji"
    }
  }

  network_interface {
    subnet_id      = "e2lrfl2ekcmg2j4mtqsu"
    ip_address     = "10.129.0.10"
    nat            = true
    nat_ip_address = "158.160.71.135"
  }

  metadata = {
    user-data = "${file("bootstrap/router.yaml")}"
  }
}