This repository is a collection of scripts to create and provision a set of
VMs that emulate a hardware HPC cluster. These VMs can be used to develop and
debug administration tasks, e.g. installation, provisioning, etc.

Here are instructions on requirements and usage:

## Requirements

1. Scripts use VMs created using libvirt, so it is necessary to
   install libvirt related packages and make sure that they work. Most
   likely user has to be present in group `kvm` and `libvirt` to allow
   VMs administraion.
2. Main node is created and provisioned using vagrant, so vagrant has
   to be installed. Modern ubuntu versions include vagrant, so no 3rd
   party repository is necessary. Vagrant requires two plugins to work.
   1. First plugin is `vagrant-reload` which allows to reboot VM from
      a vagrant script. Install it using command `vagrant plugin
      install vagrant-reload`.
   2. To operate on libvirt VMs vagrant requires `vagrant-libvirt`
      plugin. To install it you need to first install [its
      dependencies](https://github.com/vagrant-libvirt/vagrant-libvirt#installation)
      using the following commands:
      ```
      sudo apt-get build-dep vagrant ruby-libvirt
      sudo apt-get install qemu libvirt-daemon-system libvirt-clients ebtables dnsmasq-base
      sudo apt-get install libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev
      sudo apt-get install libguestfs-tools
      ```
      
      After that you can install plugin itself using command `vagrant
      plugin install vagrant-libvirt`. To verify that
      `vagrant-libvirt` plugin is successfully installed you can check
      output of `vagrant status` command, it should print `(livirt)`
      in brackets after VM status.
   3. It is recommended to also install `vagrant-scp` plugin to be
      able to transfer files to/from main VM. Use `vagrant
      plugin install vagrant-scp` to install it.
3. Main node is provisioned using ansible.
   1. Ansible included into ubuntu may work, but it is old and
      possibly it may not work. In this case try the following two
      approaches.
   2. Ansible recommends using `pip install ansible` command and
      ansible version from pip is modern and works well. It will
      however install in your system python environment. You can
      create a virtualenv or use conda approaches.
   3. Ansible exists in `conda-forge` channel, but as of time of
      writing it is broken. You can try to create a conda environment
      using command `conda create -n ansible -c conda-forge ansible`,
      if it doesn't work use a hybrid approach.
   4. I create an empty environment which contains only pip `conda
      create -n ansible pip`, activate it `conda activate ansible` and
      then install it using pip `pip install ansible`. This approach
      works well and doesn't modify my system python.
4. Ansible role `mrlesmithjr.maas` is required to install MAAS on the
   main node. To install it use the following ansible command:
   `ansible-galaxy install mrlesmithjr.maas`.

## Creating the cluster

1. First it is necessary to create the cluster network. Use
   `create-cluster-network.sh` script in the root of repository to do
   this. It creates a new network `CLUSTER_1` that contains a bridge
   called `clusbr1` on the host system. It is not connected to
   anything on the host system.
2. Go to `main` folder and create the main node. It is connected both
   to the host network and cluster network. Check that settings in
   file `settings.yaml` are good. Create, start and provision main
   node using command `vagrant up`.
3. You can now ssh to main node using command `vagrant ssh`. Default
   user on this node is called `vagrant`. On cluster network default
   IP address is `172.22.2.254` (it is configurable in
   `settings.yaml` file). On bridge connected to host system IP
   address is dynamic, so you should check what address main system
   received on interface `ens5`. It is needed to connect to MAAS web
   interface.
4. You should be able to connect to MAAS web interface from host
   system using IP address for interface `ens5`. Use URL, user and
   password from `settins.yaml` file.
5. Step through initial settings wizard. If you're on a corporate
   network, specify HTTP proxy for APT and YUM. Select desired boot
   image (these scripts were tested for Ubuntu 20.04) and synch
   (download) it to MAAS image storage.
6. Configure ssh keys to allow passwordless access. I usually reuse
   public key from `~vagrant/.ssh/authorized_keys`
   directory. Corresponding private key for it can be found in
   `.vagrant/machines/main/libvirt/private_key` on host system, but it
   is not needed for MAAS configuration.
7. After initial configuration you need to configure DHCP server for
   cluster network subnet. Go to Subnets -> `172.22.2.0/24` (if you
   used default settings) subnet -> `untagged`. Click `Enable
   DHCP`. Default settings for IP allocation are good enough. MAAS
   reserves IPs at the end of the range for dynamic allocation for VMs
   that boot from PXE and then assigns IPs from beginning of the range
   after OS is provisioned.
8. It is possible now to start cluster VMs. Go to `cluster` folder and
   create empty OS-less cluster VMs using script `create-vm.sh`.
9. Start VMs using script `start-vm.sh`. If you installed
   `virt-manager` GUI tool you can watch how VMs are booted from
   PXE. MAAS provisions init scripts that register VMs on MAAS host and
   then shut them down. It is normal. They should now apprear in MAAS
   interface on `Machines` tab.
10. MAAS assigns randomly generated host names, so after VMs shut down
    is a good time to assign some meaningful host names to them. IP
    addresses are allocated from end of range dynamic pool.
11. It is possible for MAAS to automatically control VMs power
    state. To do this MAAS has to be able to passwordlessly ssh to
    host system to a user that is allowed to run `virsh`
    command. Currently this step is not automated, so you need to
    follow steps described in
    [#2](https://github.com/gshimansky/ansible-modin/issues/2). If you
    do all those steps, go into each VM settings `Configuration` tab
    and change `Power configuration` to `Virsh`. Use
    `qemu+ssh://virsh_user_name@192.168.121.1/system` from
    [#2](https://github.com/gshimansky/ansible-modin/issues/2) as
    `Address` and VM name as ID.
    Alternatively you can start VMs up manually.
12. Select all `New` VMs and select `Take action` -> `Comission`. Use
    default scripts that MAAS offers. If power control is manual, use
    `start-vm.sh` script to start VMs. VMs automatically shut down
    after this operation again.
13. Select all `New` VMs and select `Take action` -> `Deploy`. This
    operation installs OS on the systems and they no longer shut
    down. They also receive IP addresses from the beginning of the IP
    range. Wait until MAAS reports that deployment is complete.
14. It is now should be possible to ssh to provisioned VMs. For ubuntu
    images user name is `ubuntu`. It is possible to use IP addresses
    from MAAS web console, but it is better to use host names. MAAS
    runs its own name server, so it is necessary to switch to using
    it. This step is not automated yet, so you need to do steps from
    [#1](https://github.com/gshimansky/ansible-modin/issues/1).
    Also vagrant user needs a private key from step #6, so if you
    haven't copied it into `~vagrant/.ssh/id_rsa`, do it now.
