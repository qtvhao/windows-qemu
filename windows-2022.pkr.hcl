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
  iso_url      = var.iso_path
  iso_checksum = "sha256:a6f470ca6d331eb353b815c043e327a347f594f37ff525f17764738fe812852e"
  disk_size    = 5100 # 50GB
  floppy_files = [
    // "drivers/NetKVM/2k22/amd64/*.cat",
    // "drivers/NetKVM/2k22/amd64/*.inf",
    // "drivers/NetKVM/2k22/amd64/*.sys",
    // "drivers/qxldod/2k22/amd64/*.cat",
    // "drivers/qxldod/2k22/amd64/*.inf",
    // "drivers/qxldod/2k22/amd64/*.sys",
    // "drivers/vioscsi/2k22/amd64/*.cat",
    // "drivers/vioscsi/2k22/amd64/*.inf",
    // "drivers/vioscsi/2k22/amd64/*.sys",
    // "drivers/vioserial/2k22/amd64/*.cat",
    // "drivers/vioserial/2k22/amd64/*.inf",
    // "drivers/vioserial/2k22/amd64/*.sys",
    // "drivers/viostor/2k22/amd64/*.cat",
    // "drivers/viostor/2k22/amd64/*.inf",
    // "drivers/viostor/2k22/amd64/*.sys",
    // "provision-autounattend.ps1",
    // "provision-openssh.ps1",
    // "provision-psremoting.ps1",
    // "provision-pwsh.ps1",
    // "provision-winrm.ps1",
    "windows-2022-uefi/autounattend.xml",
  ]
  accelerator  = "none"
  machine_type = "q35"
  cpus         = 2
  memory       = 4096
  qemuargs = [
    ["-cpu", "host"],
    ["-device", "qemu-xhci"],
    ["-device", "virtio-tablet"],
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-device", "virtio-net,netdev=user.0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
  ]
  disk_interface           = "virtio-scsi"
  disk_cache               = "unsafe"
  disk_discard             = "unmap"
  format                   = "qcow2"
  headless                 = true
  net_device               = "virtio-net"
  http_directory           = "."
  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
  boot_command             = ["<up><wait10m><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait>"]
  boot_wait                = "10000s"

}
build {
  sources = ["source.qemu.windows"]
  provisioner "shell" {
    inline = [
      "echo 'Hello, World!' > C:\\hello.txt"
    ]
  }
}
