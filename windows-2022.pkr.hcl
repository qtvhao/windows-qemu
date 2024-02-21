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
  // iso_url           = "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.9.0-amd64-DVD-1.iso"
  // iso_checksum      = "md5:4f58d1b19e858beb2eb4545f11904f86"

  iso_target_path = var.iso_path
  iso_url         = var.iso_path
  iso_checksum    = "sha256:a6f470ca6d331eb353b815c043e327a347f594f37ff525f17764738fe812852e"
  disk_size       = 51200 # 50GB
  floppy_files = [
    "drivers/NetKVM/2k22/amd64/*.cat",
    "drivers/NetKVM/2k22/amd64/*.inf",
    "drivers/NetKVM/2k22/amd64/*.sys",
    "drivers/qxldod/2k22/amd64/*.cat",
    "drivers/qxldod/2k22/amd64/*.inf",
    "drivers/qxldod/2k22/amd64/*.sys",
    "drivers/vioscsi/2k22/amd64/*.cat",
    "drivers/vioscsi/2k22/amd64/*.inf",
    "drivers/vioscsi/2k22/amd64/*.sys",
    "drivers/vioserial/2k22/amd64/*.cat",
    "drivers/vioserial/2k22/amd64/*.inf",
    "drivers/vioserial/2k22/amd64/*.sys",
    "drivers/viostor/2k22/amd64/*.cat",
    "drivers/viostor/2k22/amd64/*.inf",
    "drivers/viostor/2k22/amd64/*.sys",
    // "provision-autounattend.ps1",
    // "provision-openssh.ps1",
    // "provision-psremoting.ps1",
    // "provision-pwsh.ps1",
    // "provision-winrm.ps1",
    "windows-2022-uefi/autounattend.xml",
  ]
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 2
  memory       = 4096
  qemuargs = [
    // ["-cpu", "host"],
    ["-device", "qemu-xhci"],
    ["-device", "virtio-tablet"],
    // ["-device", "virtio-scsi-pci,id=scsi0"],
    // ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-device", "virtio-net,netdev=user.0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
    // -device virtio-scsi-pci,id=scsi
    // ["-device", "virtio-scsi-pci,id=scsi"],
    // ["-drive", "file=root,id=root-img,if=none,format=raw,cache=none"],
    // ["-device", "scsi-hd,drive=root-img"],
// -drive file=root,id=root-img,if=none,format=raw,cache=none
// -device scsi-hd,drive=root-img
  ]

  vnc_bind_address = "0.0.0.0"
  disk_interface   = "ide"
  // ide, sata, scsi, virtio or virtio-scsi
  // ide is slow, sata is fast, scsi is faster, virtio is fastest, virtio-scsi is fastest
  // compare virtio-scsi to scsi, virtio-scsi is faster
  // disk_cache       = "unsafe"
  // disk_discard     = "unmap"
  format           = "qcow2"
  headless         = false
  net_device       = "virtio-net"
  http_directory   = "."
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  //   communicator             = "ssh"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
  boot_command             = ["<up><wait10m><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait>"]
  boot_wait                = "10000s"
}
build {
  sources = ["source.qemu.windows"]
  //   provisioner "shell" {
  //     inline = [
  //       "echo 'Hello, World!' > C:\\hello.txt"
  //     ]
  //   }
}
