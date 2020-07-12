provider "google" {

}

variable "machine_type" {
    type = string
    default = "n1-standard-8"
}

variable "guest_accelerator_type" {
    type = string
    default = "nvidia-tesla-k80"
}

variable "guest_accelerator_count" {
    type = number
    default = 1
}

variable "disk_size" {
    type = number
    default = 100
}

variable "machine_username" {
    type = string
    default = "username"
}

variable "jupyter_port" {
    type = string
    default = "8888"
}

variable "ssh_key_path" {
    type = string
    default = "~/.ssh/id_rsa.pub"
}

//create a random id to append to our compute instance name
resource "random_id" "instance_id" {
    byte_length = 8
}

resource "google_compute_instance" "default" {
    name = "ml-automated-${random_id.instance_id.hex}"
    machine_type = var.machine_type

    //initialize our guest accelerator(s)
    guest_accelerator {
        type = var.guest_accelerator_type
        count = var.guest_accelerator_count
    }

    //initialize our boot disk with the image we want on it
    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-1804-lts"
            size = var.disk_size
        }
    }

    network_interface {

        //use the default network, we don't need anything special
        network = "default"

        access_config {
            //including this section will give the VM an external IP address
        }
    }

    //create our user here with ssh keys as the way to log in
    metadata = {
        ssh-keys = "${var.machine_username}:${file(var.ssh_key_path)}"
    }

    //set on_host_maintenance to TERMINATE as guest accelerators can't be used when it is set to MIGRATE
    scheduling {
        on_host_maintenance = "TERMINATE"
    }
}

//create our firewall rule to allow access to a Jupyter server running on our VM
resource "google_compute_firewall" "default" {
    name = "ml-automated-jupyter-${random_id.instance_id.hex}-firewall"
    network = "default"

    allow {
        protocol = "tcp"
        ports = [var.jupyter_port]
    }
}

output "ip" {
    value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}