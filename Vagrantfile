# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">=1.7.0"

$bootstrap_ovs_fedora = <<SCRIPT
#dnf -y update ||:  ; # save your time. "vagrant box update" is your friend

# loop to deal with flaky dnf
cnt=0
until [ $cnt -ge 3 ] ; do
   dnf -y -vvv install autoconf automake openssl-devel libtool \
               python3-devel \
               python3-twisted python3-zope-interface \
               desktop-file-utils groff graphviz rpmdevtools nc curl \
               wget pyftpdlib checkpolicy selinux-policy-devel \
               libcap-ng-devel kernel-devel-`uname -r` ethtool python-tftpy \
               lftp
   if [ "$?" -eq 0 ]; then break ; fi
   (( cnt++ ))
   >&2 echo "Sad panda: dnf failed ${cnt} times."
done

echo "search extra update built-in" >/etc/depmod.d/search_path.conf
SCRIPT

$bootstrap_ovs_debian = <<SCRIPT
update-alternatives --install /usr/bin/python python /usr/bin/python3 1
apt-get update
#apt-get -y upgrade  ; # save your time. "vagrant box update" is your friend
apt-get -y install build-essential fakeroot graphviz autoconf automake bzip2 \
                   debhelper dh-autoreconf libssl-dev libtool openssl procps \
                   python-all python-qt4 python-twisted-conch python-zopeinterface \
                   libcap-ng-dev libunbound-dev
SCRIPT

$bootstrap_ovs_centos7 = <<SCRIPT
#yum -y update  ; # save your time. "vagrant box update" is your friend
yum -y install autoconf automake openssl-devel libtool \
               python3-devel python3-twisted-core python3-zope-interface \
               desktop-file-utils groff graphviz rpmdevtools nc curl \
               wget pyftpdlib checkpolicy selinux-policy-devel \
               libcap-ng-devel kernel-devel-`uname -r` ethtool net-tools \
               lftp
SCRIPT

$bootstrap_ovs_centos = <<SCRIPT
#dnf -y update  ; # save your time. "vagrant box update" is your friend
dnf -y install autoconf automake openssl-devel libtool \
               python3-devel python3-pip \
               desktop-file-utils graphviz rpmdevtools nc curl \
               wget checkpolicy selinux-policy-devel \
               libcap-ng-devel kernel-devel-`uname -r` ethtool \
               lftp
echo "search extra update built-in" >/etc/depmod.d/search_path.conf
pip3 install pyftpdlib tftpy twisted zope-interface
SCRIPT

$configure_ovs = <<SCRIPT
cd /vagrant/ovs
./boot.sh
[ -f Makefile ] && ./configure && make distclean
mkdir -pv ~/build/ovs
cd ~/build/ovs
/vagrant/ovs/configure --prefix=/usr
SCRIPT

$build_ovs = <<SCRIPT
cd ~/build/ovs
make -j$(($(nproc) + 1)) V=0
make install
SCRIPT

$configure_ovn = <<SCRIPT
cd /vagrant/ovn
if [[ ! -d ${HOME}/ddlog ]] ; then
curl https://sh.rustup.rs -sSf | sh -s - -y
. $HOME/.cargo/env
rustup component add rustfmt
rustup component add clippy
curl -L https://github.com/vmware/differential-datalog/releases/download/v0.36.0/ddlog-v0.36.0-20210208063544-linux.tar.gz | tar -C ${HOME} -xzv -f -
fi
export DDLOG_HOME=${HOME}/ddlog
export PATH=${PATH}:${HOME}/ddlog/bin
. $HOME/.cargo/env
./boot.sh
[ -f Makefile ] && \
./configure --prefix=/usr --with-ovs-source=/vagrant/ovs \
  --with-ovs-build=${HOME}/build/ovs --with-ddlog=${HOME}/ddlog/lib && make distclean
mkdir -pv ~/build/ovn
cd ~/build/ovn
/vagrant/ovn/configure --prefix=/usr --with-ovs-source=/vagrant/ovs \
  --with-ovs-build=${HOME}/build/ovs --with-ddlog=${HOME}/ddlog/lib
SCRIPT

$build_ovn = <<SCRIPT
cd ~/build/ovn
export DDLOG_HOME=${HOME}/ddlog
export PATH=${PATH}:${HOME}/ddlog/bin
. $HOME/.cargo/env
make -j$(($(nproc) + 1))
make install
SCRIPT

$test_ovn = <<SCRIPT
cd ~/build/ovn
exit_rc_when_failed=0 ; # make this non-zero to halt provision
make check RECHECK=yes || {
   >&2 echo "ERROR: CHECK FAILED $?"
   exit ${exit_rc_when_failed}
}
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  vm_memory = ENV['VM_MEMORY'] || '4096'
  vm_cpus = ENV['VM_CPUS'] || '4'
  config.vm.provider 'libvirt' do |lb|
    lb.memory = vm_memory
    lb.cpus = vm_cpus
  end
  config.vm.provider "virtualbox" do |vb|
    vb.memory = vm_memory
    vb.cpus = vm_cpus
  end

  config.vm.define "debian-10" do |debian|
       debian.vm.hostname = "debian-10"
       debian.vm.box = "debian/buster64"
       debian.vm.synced_folder ".", "/vagrant", disabled: true
       debian.vm.synced_folder ".", "/vagrant/ovn", type: "rsync"
       debian.vm.synced_folder "../ovs", "/vagrant/ovs", type: "rsync"
       debian.vm.provision "bootstrap_ovs", type: "shell",
                           inline: $bootstrap_ovs_debian
       debian.vm.provision "configure_ovs", type: "shell",
                           inline: $configure_ovs
       debian.vm.provision "build_ovs", type: "shell", inline: $build_ovs
       debian.vm.provision "configure_ovn", type: "shell",
                           inline: $configure_ovn
       debian.vm.provision "build_ovn", type: "shell", inline: $build_ovn
       #debian.vm.provision "test_ovn", type: "shell", inline: $test_ovn
  end
end
