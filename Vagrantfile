# Edit these parameters
clusters = 2
nodes = 3
disk_size = 20
cluster_name = "px-test-cluster"
version = "2.1"
#version = "2.1.3"
training = false

# Set cloud to one of "aws", "gcp"
cloud = "aws"

# Set platform to one of "kubernetes", "openshift", "swarm", "rancher", "nomad", "dcos"
platform = "kubernetes"

# Set DCOS license
dcos_license="***"

# Set some cloud-specific parameters
AWS_keypair_name = "***"
AWS_sshkey_path = "#{ENV['HOME']}/.ssh/id_rsa"
AWS_type = "t3.large"

GCP_sshkey_path = "#{ENV['HOME']}/.ssh/id_rsa"
GCP_zone = "europe-west2-a"
GCP_key = "./gcp-key.json"
GCP_type = "n1-standard-2"
GCP_disk_type = "pd-standard"

# Do not edit below this line
AWS_subnet_id = "#{ENV['subnet']}"
AWS_security_group_id = "#{ENV['sg']}"
AWS_ami = "#{ENV['ami']}"
AWS_region = "#{ENV['AWS_DEFAULT_REGION']}"

if !File.exist?("id_rsa") or !File.exist?("id_rsa.pub")
    abort("Please create SSH keys before running vagrant up.")
end

open("hosts", "w") do |f|
  f << "127.0.0.1 localhost\n"
  (1..clusters).each do |c|
    f << "192.168.99.1#{c}0 master-#{c}\n"
    (1..nodes).each do |n|
      f << "192.168.99.1#{c}#{n} node-#{c}-#{n}\n"
    end
  end
end

Vagrant.configure("2") do |config|

  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  if cloud == "aws"
    config.vm.box = "dummy"
    config.vm.provider :aws do |aws, override|
      aws.security_groups = ["#{AWS_security_group_id}"]
      aws.keypair_name = "#{AWS_keypair_name}"
      aws.region = "#{AWS_region}"
      aws.instance_type = "#{AWS_type}"
      aws.ami = "#{AWS_ami}"
      aws.subnet_id = "#{AWS_subnet_id}"
      aws.associate_public_ip = true
      override.ssh.username = "centos"
      override.ssh.private_key_path = "#{AWS_sshkey_path}"
    end

  elsif cloud == "gcp"
    config.vm.box = "google/gce"
    config.vm.provider :google do |gcp, override|
      gcp.google_project_id = "#{ENV['PROJECT']}"
      gcp.zone = "#{GCP_zone}"
      gcp.google_json_key_location = "#{GCP_key}"
      gcp.image_family = "centos-7"
      gcp.machine_type = "#{GCP_type}"
      gcp.disk_type = "#{GCP_disk_type}"
      gcp.disk_size = 15
      gcp.network = "px-net"
      gcp.subnetwork = "px-subnet"
      override.ssh.username = "#{ENV['USER']}"
      override.ssh.private_key_path = "#{GCP_sshkey_path}"
    end
  end

  config.vm.provision "shell", path: "all-common"

  if platform == "k8s"
    config.vm.provision "shell", path: "k8s-common"

  elsif platform == "nomad"
    config.vm.provision "shell", path: "nomad-common"

  elsif platform == "openshift"
    config.vm.provision "shell", path: "openshift-common"

  elsif platform == "dcos"
    config.vm.provision "shell", path: "dcos-common"
  end

  if training
    config.vm.provision "shell", path: "training-common"
  end

  (1..clusters).each do |c|
    hostname_master = "master-#{c}"
    config.vm.hostname = "#{hostname_master}"
    env = { :cluster_name => cluster_name, :c => c, :version => version, :hostname_master => hostname_master, :training => training, :nodes => nodes, :dcos_license => dcos_license }

    if platform == "dcos"
      open("hosts", "a") do |f|
        f << "192.168.99.1#{c}9 bootstrap-#{c}\n"
      end
      config.vm.define "bootstrap-#{c}" do |bootstrap|
        bootstrap.vm.hostname = "bootstrap-#{c}"
        if cloud == "aws"
          bootstrap.vm.provider :aws do |aws|
            aws.private_ip_address = "192.168.99.1#{c}9"
            aws.tags = { "Name" => "bootstrap-#{c}" }
            aws.instance_type = "t3.medium"
            aws.block_device_mapping = [{ "DeviceName" => "/dev/sda1", "Ebs.DeleteOnTermination" => true, "Ebs.VolumeSize" => 10 }]
          end
        elsif cloud == "gcp"
          bootstrap.vm.provider :google do |gcp|
            gcp.name = "bootstrap-#{c}"
            gcp.network_ip = "192.168.99.1#{c}9"
          end
        end
        bootstrap.vm.provision "shell", path: "dcos-bootstrap", env: env
      end
    end

    config.vm.define "#{hostname_master}" do |master|

      if cloud == "aws"
        master.vm.provider :aws do |aws|
          aws.private_ip_address = "192.168.99.1#{c}0"
          aws.tags = { "Name" => "#{hostname_master}" }
          aws.block_device_mapping = [{ "DeviceName" => "/dev/sda1", "Ebs.DeleteOnTermination" => true, "Ebs.VolumeSize" => 15 }]
        end

      elsif cloud == "gcp"
        master.vm.provider :google do |gcp|
          gcp.name = "#{hostname_master}"
          gcp.network_ip = "192.168.99.1#{c}0"
        end
      end

      if platform == "k8s"
        master.vm.provision "shell", path: "k8s-master", env: env

      elsif platform == "swarm"
        master.vm.provision "shell", path: "swarm-master", env: env

      elsif platform == "nomad"
        master.vm.provision "shell", path: "nomad-master", env: env

      elsif platform == "rancher"
        master.vm.provision "shell", path: "rancher-master", env: env

      elsif platform == "openshift"
        master.vm.provision "shell", path: "openshift-master", env: env

      elsif platform == "dcos"
        master.vm.provision "shell", path: "dcos-master", env: env
      end
    end

    (1..nodes).each do |n|
      config.vm.define "node-#{c}-#{n}" do |node|
        node.vm.hostname = "node-#{c}-#{n}"
        if cloud == "aws"
          node.vm.provider :aws do |aws|
            aws.private_ip_address = "192.168.99.1#{c}#{n}"
            aws.tags = { "Name" => "node-#{c}-#{n}" }
            aws.block_device_mapping = [{ "DeviceName" => "/dev/sda1", "Ebs.DeleteOnTermination" => true, "Ebs.VolumeSize" => 15 }, { "DeviceName" => "/dev/sdb", "Ebs.DeleteOnTermination" => true, "Ebs.VolumeSize" => disk_size }]
          end

        elsif cloud == "gcp"
          node.vm.provider :google do |gcp|
            gcp.network_ip = "192.168.99.1#{c}#{n}"
            gcp.name = "node-#{c}-#{n}"
            gcp.additional_disks = [{ :disk_size => disk_size, :disk_name => "disk-#{c}-#{n}" }]
          end
        end

        if platform == "k8s"
          node.vm.provision "shell", path: "k8s-node", env: env

        elsif platform == "swarm"
          node.vm.provision "shell", path: "swarm-node", env: env

        elsif platform == "nomad"
          node.vm.provision "shell", path: "nomad-node", env: env

        elsif platform == "rancher"
          node.vm.provision "shell", path: "rancher-node", env: env

        elsif platform == "openshift"
          node.vm.provision "shell", path: "openshift-node", env: env

        elsif platform == "dcos"
          node.vm.provision "shell", path: "dcos-node", env: env
        end

      end
    end
  end
end
