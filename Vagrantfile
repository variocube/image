# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 4096
    libvirt.cpus = 2
    libvirt.nested = true
  end
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "src/", "/src"
  config.vm.provision "shell", run: "always", inline: <<-SHELL
    apt-get update
    apt-get install --no-install-recommends -y \
        dosfstools qemu-utils qemu-user-static debootstrap binfmt-support time \
        parted kpartx rsync curl
  SHELL
end
