# ML-InfrastructureAutomation-GCP
This repository contains Terraform and Ansible files that can be used to build a Machine Learning VM on Google Cloud Platform.

# Instructions

## Install Terraform and Ansible

Instructions for installing Terraform: https://learn.hashicorp.com/terraform/getting-started/install.html

Instructions for installing Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

## Clone the Repository

In order to run the code in this repository you need to clone it. Make sure to run:

```
git clone https://github.com/everettraven/ML-InfrastructureAutomation-GCP.git
```

## Running Terraform

### Setting Up

Before we actually run the Terraform piece of this we need to ensure we do some setup.

The first thing that needs to be done is getting a credentials file from Google Cloud Platform that will allow Terraform to perform actions on your behalf. 

Steps to do so can be found here: https://cloud.google.com/docs/authentication/getting-started

Now that we have that finished we need to create an SSH key so that we can SSH into the virtual machine once it is built (Ansible will SSH in and configure everything for us, but we still need to create an SSH key for it to pull). You can do this by running:
```
ssh-keygen
```

Next up is setting some environment variables.

The environment variables we need to set are **GOOGLE_APPLICATION_CREDENTIALS**, **GOOGLE_PROJECT**, **GOOGLE_REGION**, **GOOGLE_ZONE**. These are environment variables that Terraform pulls to set values when building the virtual machine on GCP.

**GOOGLE_APPLICATION_CREDENTIALS** - The path to your GCP credentials file
**GOOGLE_PROJECT** - The project name you'd like the virtual machine built under
**GOOGLE_REGION** - The region you would like the virtual machine built in
**GOOGLE_ZONE** - The zone you would like the virtual machine built in

#### Setting GOOGLE_APPLICATION_CREDENTIALS Example
```
export GOOGLE_APPLICATION_CREDENTIALS=<PATH/TO/CREDENTIALS_FILE>
```

#### Setting GOOGLE_PROJECT Example
```
export GOOGLE_PROJECT=<PROJECT_NAME>
```

#### Setting GOOGLE_REGION Example
```
export GOOGLE_REGION=<REGION_HERE>
```

#### Setting GOOGLE_ZONE Example
```
export GOOGLE_ZONE=<ZONE_HERE>
```

A regions and zones list for GCP can be found here: https://cloud.google.com/compute/docs/regions-zones

**NOTE**: *Replace the values surrounded with '<>' in the examples with the values you need*

Some alternative environment variables that can be set can be found here: https://www.terraform.io/docs/providers/google/guides/provider_reference.html

Now that we have our environment variables set we can continue with variables meant for this specific build process. It isn't required you set these variables as they have defaults, however if you would like to customize them you can change the values in the *terraform.tfvars.json* file (located under src/terraform). The values currently in this file are the same as the defaults, but was placed there as a template for customizing the build. This file must be kept in the same directory as *main.tf* or Terraform won't pull the values from it.

The variables specific to this build process are as follows:

**machine_type** - **TYPE: string, DEFAULT: "n1-standard-8"** - specifies the type of machine that Terraform will build. GCP machine types can be found here: https://cloud.google.com/compute/docs/machine-types

**guest_accelerator_type** - **TYPE: string, DEFAULT: "nvidia-tesla-k80"** - specifies the type of guest_accelerator (GPU) that will be attached to the virtual machine. GCP guest accelerator types can be found here: https://cloud.google.com/compute/docs/gpus/

**guest_accelerator_count** - **TYPE: number, DEFAULT: 1** - specifies the number of guest accelerators to attach to the virtual machine

**disk_size** - **TYPE: number, DEFAULT: 100** - specifies the size of the boot disk in GB. **NOTE**: *All virtual machines built with this automation process will have Ubuntu 18.04 LTS as the OS*

**machine_username** - **TYPE: string, DEFAULT: "username"** - specifies the username that will be used to access the virtual machine. It is recommended that you change this to something more secure.

**jupyter_port** - **TYPE: string, DEFAULT: "8888"** - specifies the port that will be opened in the firewall for TCP traffic. This will allow the Jupyter Server to run on this port.

**ssh_key_path** - **TYPE: string, DEFAULT: "~/.ssh/id_rsa.pub"** - specifies the path to the public ssh key for setting up ssh to the virtual machine.

### Actually Running Terraform

Now that setup is out of the way we can actually run Terraform and have it provision everything for us!

#### Initialize Terraform

First we need to initialize Terraform. To do this, we change directories into the directory that contains all our Terraform information (in this case src/terraform) and run:

```
terraform init
```

**NOTE:** *Depending on your setup, you may need to run this as root*

#### Check the Terraform Plan

Now that we have initialized Terraform, we can check its build plan to make sure it will build what we are wanting. To do this, run:

```
terraform plan
```

#### Apply the Terraform Plan

Once we are certain everything checks out with the build plan, it's time to build it. To do this, run:

```
terraform apply
```

When prompted, type 'yes' if you are sure you want Terraform to run the build plan or 'no' to cancel.

Now once this is finished, it will output an IP address to your virtual machine. Make note of this as we are going to be using this to run the Ansible playbook for configuration.


If you run into any issues, or would like to take down your virtual machine at any time (GCP does charge money for these compute instances) you can run:

```
terraform destroy
```

This will destroy the virtual machine and you will need to build a new one if you decide you want to use one again.


## Run Ansible

Now that Terraform has built the virtual machine we can use Ansible to configure the virtual machine and run Jupyter.

### Setting Up Ansible Variables

The Ansible Playbook used does have some variables that have defaults but can be customized. If you customized the Terraform build, you will likely need to change these. The file that ansible pulls can be found in */src/group_vars* and is named *all.yml*.

The variables are as follows:

**machine_username** - **TYPE: string, DEFAULT: "username"** - specifies the username Ansible will use when trying to SSH into the virtual machine. If you changed the default in the Terraform variables, you must change this to the same as you set for the Terraform variables. It is recommended you change this to something more secure.

**jupyter_port** - **TYPE: string, DEFAULT: "8888"** - specifies the port that Jupyter will be run on. If you changed the default in the Terraform variables, you must change this to the same as you set for the Terraform variables.

**jupyter_token** - **TYPE: string, DEFAULT: "temporarytoken"** - specifies the token that Jupyter will use to authenticate and allow access to the Jupyter Notebook interface. It is recommended you change this to something more secure.


### Running the Ansible Playbook

In order to the run the Ansible Playbook and configure the virtual machine, run:

```
ansible-playbook -i <VIRTUAL_MACHINE_IP>, --private-key=<PATH/TO/PRIVATE_SSH_KEY> <PATH/TO/ANSIBLE_PLAYBOOK>
```

Now, browse to the virtual machine ip address followed by the port used for Jupyter (<VIRTUAL_MACHINE_IP>:<PORT>) and start doing some machine learning!

