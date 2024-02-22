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
source "qemu" "windows-development-environment" {
  //   iso_target_path = var.iso_path
  iso_url          = var.iso_path
  disk_image       = true
  use_backing_file = true
  iso_checksum     = "none"
  //   iso_checksum    = "sha256:a6f470ca6d331eb353b815c043e327a347f594f37ff525f17764738fe812852e"
  disk_size = 51200 # 50GB
  floppy_files = [
    // "provision-autounattend.ps1",
    // "provision-openssh.ps1",
    // "provision-psremoting.ps1",
    // "provision-pwsh.ps1",
    // "provision-winrm.ps1",
    // "windows-2022-uefi/autounattend.xml",
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
  // boot_command             = ["<wait300>"]
  boot_wait = "60s"
}
build {
  sources = ["source.qemu.windows-development-environment"]
    provisioner "powershell" {
    inline = [
      "Write-Output 'TASK COMPLETED: VM booted'",
      "New-Item -Path 'C:\\Users\\vagrant\\Desktop\\provision-files' -ItemType 'directory' -Force",
    ]
  }
  provisioner "file" {
    source = "provision-files"
    destination = "C:\\Users\\vagrant\\Desktop\\provision-files"
  }
  provisioner "powershell" {
    inline = [
      "Set-ItemProperty -Path HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Audiosrv -Name Start -Value 00000002",
      "Write-Output 'TASK COMPLETED: Audio enabled'",

      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "Write-Output 'TASK COMPLETED: Chocolatey installed'",

      "choco install -y 7zip",
      "choco install -y nodejs",
      "choco install -y googlechrome",
      "choco install -y git",
      "Write-Output 'TASK COMPLETED: Chocolatey packages installed...'",
    ]
  }

  # Restart VM
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  }
}
