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
variable "ovf_file_2" {
  type    = string
  default = "./output-windows-development-environment/packer-windows-development-environment-1709042403.ovf"
}
source "virtualbox-ovf" "windows-development-tools" {
  source_path      = var.ovf_file
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  shutdown_command = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nic1", "nat", "--natpf1", "ssh,tcp,,2222,,22"],
  ]
}
build {
  sources = ["source.virtualbox-ovf.windows-development-tools"]
  provisioner "powershell" {
    inline = [
      "Set-ItemProperty -Path HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Audiosrv -Name Start -Value 00000002",
      "Write-Output 'TASK COMPLETED: Audio enabled'",

      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "Write-Output 'TASK COMPLETED: Chocolatey installed'",

      "choco install -y nodejs",
      "choco install -y git",
      "choco install -y 7zip",
      "choco install -y yarn",
      "choco install -y virtualbox-guest-additions-guest.install",
    ]
  }
  # Restart VM
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  }
  provisioner "powershell" {
    inline = [
      // "while (!(Test-Path -Path 'a')) { Start-Sleep -Seconds 60; Write-Output 'Waiting for file a to be created...'}",
      "Write-Output 'TASK COMPLETED: Chocolatey packages installed...'",
      "Write-Output 'TASK COMPLETED: VM provisioned'",
    ]
  }

  # Restart VM
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  }
}
