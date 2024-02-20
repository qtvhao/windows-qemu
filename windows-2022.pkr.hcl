packer {
  required_plugins {
    qemu = {
      version = "1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}
variable "iso_path" {
  type    = string
  default = "/root/windows.iso"
}
source "qemu" "windows" {
  iso_url = var.iso_path
  disk_size = 51200 # 50GB
}
build {
  sources = ["source.qemu.windows"]
  provisioner "shell" {
    inline = [
      "echo 'Hello, World!' > C:\\hello.txt"
    ]
  }
}
