variable "iso_path" {
  type    = string
  default = "/root/windows.iso"
}
source "qemu" "windows" {
  iso_url = var.iso_path
  disk {
    size = "50G"
  }
}
// use packer to build the image: packer build windows.json
