# Edit these parameters
clusters = 2
nodes = 3
disk_size = 20
cluster_name = "px-test-cluster"
version = "2.3.2"
journal = false
training = false

# Set cloud to one of "aws", "gcp"
cloud = "aws"

# Set platform to one of "k8s", "openshift", "swarm", "rancher", "nomad", "dcos"
platform = "k8s"

# Set K8s version
k8s_version="1.16.4"

# Set DCOS license
dcos_license="***"

# Set some cloud-specific parameters
AWS_keypair_name = "CHANGEME"
AWS_sshkey_path = "#{ENV['HOME']}/.ssh/id_rsa"
AWS_type = "t3.large"
AWS_hostname_prefix = ""

GCP_sshkey_path = "#{ENV['HOME']}/.ssh/id_rsa"
GCP_zone = "#{ENV['GCP_REGION']}-b"
GCP_key = "./gcp-key.json"
GCP_type = "n1-standard-2"
GCP_disk_type = "pd-standard"

# Do not edit below this line
system("ssh-keygen -t rsa -b 2048 -f id_rsa -N ''") if !File.exist?("id_rsa")
File.delete("id_rsa.pub") if File.exist?("id_rsa.pub")

Vagrant.configure("2") do |config|

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provision "file", source: "id_rsa", destination: "/tmp/id_rsa"

  if cloud == "aws"
    config.vm.box = "dummy"
    config.vm.provider :aws do |aws, override|
      aws.security_groups = ENV['AWS_sg']
      aws.keypair_name = AWS_keypair_name
      aws.region = ENV['AWS_region']
      aws.instance_type = AWS_type
      aws.ami = ENV['AWS_ami']
      aws.subnet_id = ENV['AWS_subnet']
      aws.associate_public_ip = true
      aws.block_device_mapping = [{ :DeviceName => "/dev/sda1", "Ebs.DeleteOnTermination" => true, "Ebs.VolumeSize" => 15 }]
      override.ssh.username = "centos"
      override.ssh.private_key_path = AWS_sshkey_path
    end
  elsif cloud == "gcp"
    config.vm.box = "google/gce"
    config.vm.provider :google do |gcp, override|
      gcp.google_project_id = ENV['GCP_PROJECT']
      gcp.zone = GCP_zone
      gcp.google_json_key_location = GCP_key
      gcp.image_family = "centos-7"
      gcp.machine_type = GCP_type
      gcp.disk_size = 15
      gcp.network = "px-net"
      gcp.subnetwork = "px-subnet"
      gcp.metadata = { "px-cloud_owner" => ENV['GCP_owner_tag'] }
      override.ssh.username = ENV['USER']
      override.ssh.private_key_path = GCP_sshkey_path
    end
  end

  env_ = { :cluster_name => cluster_name, :version => version, :journal => journal, :training => training, :nodes => nodes, :clusters => clusters, :dcos_license => dcos_license, :k8s_version => k8s_version }
  config.vm.provision "shell", path: "all-common", env: env_
  config.vm.provision "shell", path: "#{platform}-common", env: env_
  config.vm.provision "shell", path: "training-common" if training

  (1..clusters).each do |c|
    subnet = "192.168.#{100+c}"
    config.vm.hostname = "master-#{c}"
    env = env_.merge({ :c => c })

    if platform == "dcos"
      config.vm.define "bootstrap-#{c}" do |bootstrap|
        bootstrap.vm.hostname = "bootstrap-#{c}"
        if cloud == "aws"
          bootstrap.vm.provider :aws do |aws|
            aws.private_ip_address = "192.168.#{100+c}.80"
            aws.tags = { "px-cloud_owner" => ENV['AWS_owner_tag'], "Name" => "#{AWS_hostname_prefix}bootstrap-#{c}" }
          end
        elsif cloud == "gcp"
          bootstrap.vm.provider :google do |gcp|
            gcp.name = "bootstrap-#{c}"
            gcp.network_ip = "192.168.#{100+c}.80"
          end
        end
        bootstrap.vm.provision "shell", path: "dcos-bootstrap", env: env
      end
    end

    config.vm.define "master-#{c}" do |master|
      if cloud == "aws"
        master.vm.provider :aws do |aws|
          aws.private_ip_address = "#{subnet}.90"
          aws.tags = { "px-cloud_owner" => ENV['AWS_owner_tag'], "Name" => "#{AWS_hostname_prefix}master-#{c}" }
        end
      elsif cloud == "gcp"
        master.vm.provider :google do |gcp|
          gcp.name = "master-#{c}"
          gcp.network_ip = "#{subnet}.90"
        end
      end
      master.vm.provision "shell", path: "#{platform}-master", env: env
    end

    (1..nodes).each do |n|
      config.vm.define "node-#{c}-#{n}" do |node|
        node.vm.hostname = "node-#{c}-#{n}"
        if cloud == "aws"
          node.vm.provider :aws do |aws|
            aws.private_ip_address = "192.168.#{100+c}.#{100+n}"
            aws.tags = { "px-cloud_owner" => ENV['AWS_owner_tag'], "Name" => "#{AWS_hostname_prefix}node-#{c}-#{n}" }
            aws.block_device_mapping.push({ :DeviceName => "/dev/sdb", "Ebs.DeleteOnTermination" => true, "Ebs.VolumeSize" => disk_size })
            aws.block_device_mapping.push({ :DeviceName => "/dev/sdc", "Ebs.DeleteOnTermination" => true, "Ebs.VolumeSize" => 3 }) if journal
          end
        elsif cloud == "gcp"
          node.vm.provider :google do |gcp|
            gcp.network_ip = "192.168.#{100+c}.#{100+n}"
            gcp.name = "node-#{c}-#{n}"
            gcp.additional_disks = [{ :disk_size => disk_size, :disk_name => "disk-#{c}-#{n}" }]
            gcp.additional_disks.push({ :disk_size => 3, :disk_name => "journal-#{c}-#{n}" }) if journal
          end
        end
        node.vm.provision "shell", path: "#{platform}-node", env: env
      end
    end
  end
end
