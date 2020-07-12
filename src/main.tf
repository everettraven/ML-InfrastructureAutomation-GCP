provider "google" {
    # credentials = file("credentials.json") //replace this with your credentials file
    # project = "flower-gan" //replace this with your project name
    # region = "us-central1"
}

//create a random id to append to our compute instance name
resource "random_id" "instance_id" {
    byte_length = 8
}

resource "google_compute_instance" "default" {
    name = "stock-prediction-${random_id.instance_id.hex}"
    machine_type = "n1-standard-8"
    # zone = "us-central1-a"

    //initialize our guest accelerator(s)
    guest_accelerator {
        type = "nvidia-tesla-k80"
        count = 1
    }

    //initialize our boot disk with the image we want on it
    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-1804-lts"
            size = 100
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
        ssh-keys = "mrpalmer:${file("~/.ssh/id_rsa.pub")}"
    }

    //set on_host_maintenance to TERMINATE as guest accelerators can't be used when it is set to MIGRATE
    scheduling {
        on_host_maintenance = "TERMINATE"
    }
}

//create our firewall rule to allow access to a Jupyter server running on our VM
resource "google_compute_firewall" "default" {
    name = "stock-prediction-${random_id.instance_id.hex}-firewall"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["8888"] //running Jupyter on port 8888, change this if youd like
    }
}

output "ip" {
    value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}