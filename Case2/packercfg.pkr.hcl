variable "vm_name" {
  default = "k8s_cilium_only"
}

variable "iso_url" {
  default = "http://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
}

variable "iso_checksum" {
  default = "sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

source "virtualbox-iso" "ubuntu" {
  iso_url            = var.iso_url
  iso_checksum       = var.iso_checksum
  iso_checksum_type  = "sha256"
  guest_os_type      = "Ubuntu_64"
  vm_name            = var.vm_name
  ssh_username       = "packer"
  ssh_password       = "packer"
  ssh_timeout        = "20m"
  shutdown_command   = "echo 'packer' | sudo -S shutdown -P now"
  vboxmanage         = [
    ["modifyvm", "{{.Name}}", "--memory", "2048"],
    ["modifyvm", "{{.Name}}", "--cpus", "2"]
  ]
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet=1.29.0-00 kubeadm=1.29.0-00 kubectl=1.29.0-00",
      "curl -L --output cilium-cli.tar.gz https://github.com/cilium/cilium-cli/releases/download/v0.15.5/cilium-linux-amd64.tar.gz",
      "tar -xzf cilium-cli.tar.gz -C /usr/local/bin/",
      "sudo kubeadm init --pod-network-cidr=10.244.0.0/16",
      "sudo /usr/local/bin/cilium install --kubeconfig /etc/kubernetes/admin.conf",
      "kubectl label node $(hostname) node-role.kubernetes.io/master-"
    ]
  }

  post-processor "vagrant" {
    output = "output/{{user `vm_name`}}.box"
  }

  post-processor "virtualbox-ovf" {
    output = "output/{{user `vm_name`}}.ova"
  }
}
