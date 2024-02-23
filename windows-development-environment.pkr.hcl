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
variable "iso_path" {
  type    = string
  default = "./output-windows-1708535165/packer-windows"
}
variable "test_path" {
  type = string
}
source "qemu" "windows-development-environment" {
  //   iso_target_path = var.iso_path
  iso_url          = var.iso_path
  disk_image       = true
  use_backing_file = true
  iso_checksum     = "none"
  //   iso_checksum    = "sha256:a6f470ca6d331eb353b815c043e327a347f594f37ff525f17764738fe812852e"
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
  sources = ["source.qemu.windows-development-environment"]
  // provisioner "windows-restart" {
  //   restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  // }
  provisioner "powershell" {
    inline = [
      "Write-Output 'TASK COMPLETED: VM booted'",
      "New-Item -Path 'C:\\Users\\vagrant\\Desktop\\provision-files' -ItemType 'directory' -Force",
    ]
  }
  provisioner "file" {
    source      = "provision-files"
    destination = "C:\\Users\\vagrant\\Desktop\\provision-files"
  }
  provisioner "powershell" {
    inline = [
      "while (!(Test-Path -Path '${var.test_path}')) { Start-Sleep -Seconds 5; Write-Output 'Waiting for file to be created...'}",
      "Set-ItemProperty -Path HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Audiosrv -Name Start -Value 00000002",
      "Write-Output 'TASK COMPLETED: Audio enabled'",

      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "Write-Output 'TASK COMPLETED: Chocolatey installed'",

      "choco install -y 7zip",
      "choco install -y nodejs",
      "choco install -y googlechrome",
      "choco install -y git",
      "Write-Output 'TASK COMPLETED: Chocolatey packages installed...'",
      "Write-Output 'TASK COMPLETED: VM provisioned'",
    ]
  }

  # Restart VM
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  }
}
