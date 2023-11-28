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

#################### ROUTER HOST ###################

resource "yandex_compute_instance" "router" {
  name        = "router"
  platform_id = "standard-v1"
  zone        = "ru-central1-b"
  hostname    = "router"

  resources {
    cores  = 2
    memory = 2
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

#################### NFS HOST ######################

resource "yandex_compute_instance" "nfs" {
  name               = "nfs"
  platform_id        = "standard-v1"
  zone               = "ru-central1-b"
  hostname           = "nfs"
  service_account_id = "ajedf837co7ndvhrfbef"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd811ke2vnjc423tj8ji"
    }
  }

  network_interface {
    subnet_id      = "e2lrfl2ekcmg2j4mtqsu"
    ip_address     = "10.129.0.20"
    nat            = false
  }

  metadata = {
    user-data = "${file("bootstrap/nfs.yaml")}"
  }

  depends_on = [yandex_compute_instance.router]
}

#################### APP HOST ######################

resource "yandex_compute_instance" "app" {
  name               = "app-1"
  platform_id        = "standard-v1"
  zone               = "ru-central1-b"
  hostname           = "app-1"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8un8f40qgmlenpa0qb"
    }
  }

  network_interface {
    subnet_id      = "e2lrfl2ekcmg2j4mtqsu"
    ip_address     = "10.129.0.30"
    nat            = false
  }

  metadata = {
    user-data = "${file("bootstrap/app.yaml")}"
  }

  depends_on = [yandex_compute_instance.nfs]
}

#################### OBSERVABILITY HOST ######################

resource "yandex_compute_instance" "observability" {
  name               = "observability"
  platform_id        = "standard-v1"
  zone               = "ru-central1-b"
  hostname           = "observability"

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
    ip_address     = "10.129.0.40"
    nat            = false
  }

  metadata = {
    user-data = "${file("bootstrap/observability.yaml")}"
  }

  depends_on = [yandex_compute_instance.router]
}