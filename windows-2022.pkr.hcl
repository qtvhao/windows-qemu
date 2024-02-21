packer {
  required_plugins {
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
    "provision-autounattend.ps1",
    "provision-openssh.ps1",
    "provision-psremoting.ps1",
    "provision-pwsh.ps1",
    "provision-winrm.ps1",
    "windows-2022-uefi/autounattend.xml",
  ]
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 6
  memory       = 12288
  qemuargs = [
    ["-cpu", "host"],
    ["-device", "qemu-xhci"],
    ["-device", "virtio-tablet"],
    // ["-device", "virtio-scsi-pci,id=scsi0"],
    // ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    // ["-device", "virtio-net,netdev=user.0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
  ]

  vnc_bind_address = "0.0.0.0"
  disk_interface   = "ide"
  disk_cache       = "unsafe"
  disk_discard     = "unmap"
  format           = "qcow2"
  headless         = false
  // net_device (string) - The driver to use for the network interface.
  // Allowed values ne2k_pci, i82551, i82557b, i82559er, rtl8139, e1000, pcnet, virtio, virtio-net, virtio-net-pci, usb-net, i82559a, i82559b, i82559c, i82550, i82562, i82557a, i82557c, i82801, vmxnet3, i82558a or i82558b. The Qemu builder uses virtio-net by default.
  net_device               = "e1000"
  http_directory           = "."
  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
  boot_command             = ["<enter><wait30><enter><wait30><enter><wait30><enter><wait30><enter><wait30><enter><wait300>"]
  boot_wait                = "10m"
}
build {
  sources = ["source.qemu.windows"]


  provisioner "powershell" {
    use_pwsh = true
    script   = "disable-windows-updates.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "disable-windows-defender.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    only     = ["qemu.windows-2022-amd64"]
    script   = "provision-guest-tools-qemu-kvm.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision.ps1"
  }

  provisioner "windows-update" {
  }

  // post-processor "vagrant" {
  //   vagrantfile_template = "Vagrantfile.template"
  // }
}
