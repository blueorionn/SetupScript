source "digitalocean" "debian" {
  image     = "debian-12-x64"
  region    = "nyc3"
  size      = "s-1vcpu-1gb"
  ssh_username = "root"
  api_token = "{{env `DO_API_TOKEN`}}"
}

build {
  sources = ["source.digitalocean.debian"]
  
  provisioner "shell" {
    inline = [
      # Create a non-sudo admin user
      "useradd -m -s /bin/bash admin",
      "mkdir -p /home/admin/.ssh",
      "chown -R admin:admin /home/admin/.ssh",
      "chmod 700 /home/admin/.ssh",
      
      # Add user to sudoers group
      "usermod -aG sudo admin"
      
      # Enable SSH for the admin user
      "cp /root/.ssh/authorized_keys /home/admin/.ssh/authorized_keys",
      "chown admin:admin /home/admin/.ssh/authorized_keys",
      "chmod 600 /home/admin/.ssh/authorized_keys"
    ]
  }
}
