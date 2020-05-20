Example of using [Terraform](https://www.terraform.io/) with the [`stackhpc.openhpc`](https://galaxy.ansible.com/stackhpc/openhpc) Ansible role to deploy a Slurm cluster with a shared NFS-exported fileystem.

This demonstrates:
- Using ansible configuration (`group_vars/all.yml`) as input for terraform so there is a single source of config.
- Adding the terraform control hostname and path of the terraform working dir to the deployed nodes' metadata - this is available in Horizon and helps work out where to go to modify those hosts!

# Deployment Host Setup

The hosts we're using for the workshop already have several things set up:
- `git`, `python`, `pip`, `virtualenv`, `wget` and `unzip` installed.
- A virtualenv at `~/venv` which has `openstacksdk` and `ansible` installed.
- `terraform` installed.
- An openstack rc file and a `~/.config/openstack/clouds.yaml` file to authenticate against openstack.
- An ssh keypair at `~/.ssh/id_rsa{.pub}`.

To complete setup we just need to clone this repo and download the Ansible roles it needs from Ansible Galaxy:

    cd
    . ~/venv/bin/activate   # makes openstack and ansible available
    git clone https://github.com/stackhpc/tf-demo.git   # this repo
    cd tf-demo
    ansible-galaxy install -r requirements.yml


# Deployment and Configuration

1. In `group_vars/all.yml`:
   - Change `instance_prefix` to your name or `lab*` username.
   - Comment/uncomment the appropriate `network` for the jumphost you're on

2. Deploy infrastructure using Terraform:

        terraform init
        terraform plan
        terraform apply

   This will generate a file `./inventory`.

Wait a couple of minutes for the instances to boot.

3. Install and configure software using Ansible:
    
        . ~/venv/bin/activate
        ansible-playbook -i inventory install.yml

    The created cluster will have a shared NFS filesystem at `/mnt/nfs`.

4. To log in to the cluster use:

        ssh centos@<ssh_proxy>

   where `ssh_proxy` is given in the inventory.
    

5. To destroy the cluster when done:

        terraform destroy
