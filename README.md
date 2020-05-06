Example of using [Terraform](https://www.terraform.io/) with the [`stackhpc.openhpc`](https://galaxy.ansible.com/stackhpc/openhpc) Ansible role to deploy a Slurm cluster with a shared NFS-exported fileystem.

This demonstrates:
- Using ansible configuration (`group_vars/all.yml`) as input for terraform so there is a single source of config.
- Adding the terraform control hostname and path of the terraform working dir to the deployed nodes' metadata - this is available in Horizon and helps work out where to go to modify those hosts!

# Setup Deloyment Environment

Your deployment environment should have the following commands available:
- `git`
- `python`
- `pip`
- `virtualenv`
- `wget`
- `unzip`

If on centos7 with sudo rights you can run:

```shell
sudo yum install -y epel-release
sudo yum install -y git
sudo yum install -y python-pip
sudo pip install -U pip # updates pip
sudo pip install virtualenv
sudo yum install -y wget
sudo yum install -y unzip
```

Now clone this repo:
```shell
git clone git@github.com:stackhpc/tf-demo.git
```

Make and activate a virtualenv, then install ansible, the openstack sdk and an selinux shim via `pip`:
```shell
cd tf-demo
virtualenv .venv
. .venv/bin/activate
pip install -U pip
pip install -U -r requirements.txt # ansible, openstack sdk and selinux shim
```

Install StackHPC's ansible roles from ansible-galaxy (https://galaxy.ansible.com/stackhpc):
```shell
ansible-galaxy install -r requirements.yml
```
(Note the versions of these are pinned - not essential here but good practice!)

Install terraform:
```shell
wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip terraform*.zip
sudo cp terraform /bin # or ~/.bin or wherever is on your path
```

Create a [`clouds.yaml`](https://docs.openstack.org/openstacksdk/latest/user/config/configuration.html#config-files) file with your credentials for the Openstack project to use - see `clouds.yaml.example` if necessary.

# Deployment and Configuration

If you want to use a new ssh keypair to connect to the nodes, create it now.

Modify `group_vars/all.yml` appropriately then deploy infrastructure using Terraform:

```shell
cd tf-demo
terraform init
terraform plan
terraform apply
```

Then install and configure nodes using Ansible:
```shell
. .venv/bin/activate
ansible-playbook -i inventory install.yml
```

This will generate a file `inventory`.

To log in to the cluster:
```shell
ssh <ansible_ssh_common_args> centos@<slurm_control_ip>
```
where:
- `ansible_ssh_common_args` is given in the `inventory`
- `slurm_control_ip` is from the `ansible_host` parameter for the `slurm_control` node in the `inventory`

The created cluster will have a shared NFS filesystem at `/mnt/nfs`.

To destroy the cluster when done:
```shell
terraform destroy
```
