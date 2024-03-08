packer {
  required_plugins {
    // vagrant = {
    //   version = "~> 1"
    //   source  = "github.com/hashicorp/vagrant"
    // }
    // qemu = {
    //   version = "1.0.10"
    //   source  = "github.com/hashicorp/qemu"
    // }
    // windows-update = {
    //   version = "0.15.0"
    //   source  = "github.com/rgl/windows-update"
    // }
  }
}
variable "disk_image_path" {
  type    = string
  default = "./output-windows-1708535165/packer-windows"
}
variable "test_path" {
  type = string
}
variable "ovf_file" {
  type    = string
  default = "./windows-updated/packer-windows-installed-1709014984.ovf"
}
source "virtualbox-ovf" "windows-development-environment" {
  source_path      = var.ovf_file
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  vboxmanage = [
  // add port 3369 to 3389 for RDP
    ["modifyvm", "{{.Name}}", "--natpf1", "rdp,tcp,,3369,,3389"],
    // [ "modifyvm", "{{.Name}}", "--firmware", "EFI" ],
  ]
}
source "qemu" "windows-development-environment" {
  iso_url          = var.disk_image_path
  disk_image       = true
  use_backing_file = true
  iso_checksum     = "none"
  disk_size = 51200 # 50GB
  floppy_files = [
  ]
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 6
  memory       = 12288
  qemuargs = [
    ["-cpu", "host"],
    ["-device", "qemu-xhci"],
    ["-device", "e1000,netdev=user.0"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::2222-:22,hostfwd=tcp::3369-:3389"],
    ["-device", "virtio-tablet"],
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
  skip_nat_mapping = true
  ssh_port         = 2222
  ssh_host         = "127.0.0.1"
  disk_cache       = "unsafe"
  disk_discard     = "unmap"
  format           = "qcow2"
  headless         = false

  net_device               = "e1000"
  http_directory           = "."
  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
  boot_wait                = "60s"
}
build {
  sources = ["source.virtualbox-ovf.windows-development-environment"]
  // provisioner "windows-restart" {
  //   restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  // }
  provisioner "powershell" {
    inline = [
      "Write-Output 'TASK COMPLETED: VM booted'",
      "New-Item -Path 'C:\\Users\\vagrant\\Desktop\\provision-files' -ItemType 'directory' -Force",
    ]
  }
  provisioner "powershell" {
    inline = [
      "while (!(Test-Path -Path '${var.test_path}')) { Start-Sleep -Seconds 60; Write-Output 'Waiting for file ${var.test_path} to be created...'}",
    ]
  }

  # Restart VM
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  }
}
