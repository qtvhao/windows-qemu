packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
    qemu = {
      version = "1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
    windows-update = {
      version = "0.15.0"
      source  = "github.com/rgl/windows-update"
    }
  }
}
variable "ovf_file" {
  type    = string
  default = "./output-windows-virtualbox/packer-windows-virtualbox-1708999724.ovf"
}
variable "vmdk_file" {
  type    = string
  default = "./output-windows-virtualbox/packer-windows-virtualbox-1708999724-disk001.vmdk"
}
variable "source_path" {
  type    = string
  default = "./output-windows-virtualbox/"

}
source "virtualbox-ovf" "windows-installed" {
  source_path = var.ovf_file
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
}

build {
  sources = [
    "source.virtualbox-ovf.windows-installed"
  ]
  provisioner "windows-update" {
  }
}
