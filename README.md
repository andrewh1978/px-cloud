# What

This will provision one or more CentOS clusters, along with Portworx, in the cloud.

# Supported platforms

## Container
 * Kubernetes
 * Openshift
 * Nomad
 * Rancher
 * DC/OS
 * Swarm

## Cloud
 * AWS
 * GCP

# How

1. Install the CLI for your choice of cloud provider:
 * AWS: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
 * GCP: https://cloud.google.com/sdk/docs/quickstarts

2. Install [Vagrant](https://www.vagrantup.com/downloads.html).

3. (Only required for AWS) Ensure you have `jq` installed, eg:
```
# brew install jq
# yum install jq
# apt install jq
```

4. Install the Vagrant plugin for your choice of cloud provider:
 * AWS: `vagrant plugin install vagrant-aws`
 * GCP: `vagrant plugin install vagrant-google`

Note: For AWS, also need to install a dummy box:
```
vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
```

5. Clone this repo and cd to it.

6. Configure cloud-specific environment and project/VPC:
 * AWS: Edit aws-create-vpc.sh and change AWS_region as required (you need to ensure this matches the region set in `$HOME/.aws/config` until https://github.com/mitchellh/vagrant-aws/pull/564 is merged)
 * GCP: Edit gcp-create-project.sh and change GCP_PROJECT and GCP_REGION as required

7. Create cloud-specific VPC/project:
 * AWS: `sh aws-create-vpc.sh`
 * GCP: `sh gcp-create-project.sh`

Notes for GCP:
 * Billing needs to be enabled:
```
gcloud alpha billing projects link $PROJECT --billing-account $(gcloud alpha billing accounts list | tail -1 | cut -f 1 -d " ")
```
 * Create JSON service account key: On GCP console, select the Project, click APIs and Services, Credentials, Create Credentials, Service account key, Create. Save the file.

8. Edit `Vagrantfile`.
 * `clusters`: number of clusters
 * `nodes`: number of nodes per cluster
 * `disk_size`: size of storage disk in GB
 * `cluster_name`: name of cluster (except in Kubernetes and Openshift, where it will be `$clustername-$n`, where `$n` is the cluster number)
 * `version`: Portworx version
   * leave blank to determine latest version from install.portworx.com
   * otherwise it should be the name as the Docker tag, eg `2.1.5`
 * `journal`:
    * `false`: no journal
    * `true`: provision 3GB volume for journal
 * `training`: only applies to Kubernetes and Openshift
   * `false`: install Portworx
   * `true`:
     * do not install Portworx
     * install [shellinabox](https://github.com/shellinabox/shellinabox) (this will listen on port 443 of each node)
     * set root password to `portworx`
 * `cloud`: set to one of `aws`, `gcp`
 * `platform`: set to one of `kubernetes`, `openshift`, `swarm`, `rancher`, `nomad`, `dcos`
 * `dcos_license`: DC/OS license hash
 * `tags`: name/value pairs to be used for AWS tags or GCP metadata

There are also some cloud-specific variables below this section that may need to be modified. They all begin with `AWS_` and `GCP_`.
 * `AWS_keypair_name`: change to your keypair name
 * `AWS_sshkey_path`: the private SSH key associated with the AWS keypair
 * `AWS_type`: t3.large is the default, t3.medium also works
 * `AWS_hostname_prefix`: set prefix for hostnames on AWS
 * `GCP_key`: path to the service account key saved above

9. Source the cloud-specific environment:
 * AWS: `. aws-env.sh`
 * GCP: `. gcp-env.sh`

10. Start the cluster(s):
```
$ vagrant up
```

11. Destroy the cluster(s):
```
$ vagrant destroy -fp
```

12. Destroy cloud-specific VPC/project:
```
$ sh aws-delete-vpc.sh
$ sh gcp-delete-project.sh
```

# Notes:
 * The DC/OS UI username and password are `admin`/`admin`.
 * The `status.sh` script will output a list of master nodes and IP addresses, useful for training sessions:
```
$ sh status.sh
master-1 34.245.47.251 ec2-34-245-47-251.eu-west-1.compute.amazonaws.com
master-2 34.252.74.216 ec2-34-252-74-216.eu-west-1.compute.amazonaws.com
master-3 34.245.11.144 ec2-34-245-11-144.eu-west-1.compute.amazonaws.com
...
```

If you need a list of VM IDs for whitelisting, use:
```
aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpc" --query 'Reservations[*].Instances[*].[InstanceId]' --output text
```
