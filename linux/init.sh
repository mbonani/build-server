#!/bin/sh
set -eu
cd `dirname "$0"`

mkdir --parents ~/.ssh
cp authorized_keys ~/.ssh/authorized_keys

curl --output /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum --assumeyes install epel-release
yum --assumeyes install java jenkins git debootstrap dpkg-dev lftp yum-cron
yum --assumeyes upgrade

sed --in-place "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
systemctl enable yum-cron

cp jenkins/sudoers /etc/sudoers.d/jenkins
cp jenkins/init.groovy /var/lib/jenkins/init.groovy
cp jenkins/gitconfig /var/lib/jenkins/.gitconfig
cp jenkins/netrc /var/lib/jenkins/.netrc
chown jenkins:jenkins /var/lib/jenkins/.netrc
systemctl enable jenkins.service

jenkins_uid=`id --user jenkins`
jenkins_gid=`id --group jenkins`

# ubuntu
for release in precise trusty vivid
do
	for arch in amd64 i386
	do
		machine="$release-$arch"
		container="/var/lib/container/$machine"

		debootstrap "--arch=$arch" --include=equivs,git-buildpackage,sudo --components=main,universe --variant=buildd "$release" "$container" http://archive.ubuntu.com/ubuntu/
		# precise doesn't have this file
		touch "$container/etc/os-release"

		systemd-nspawn "--directory=$container" --bind=/srv/linux --bind=/var/lib/jenkins /srv/linux/deb-init.sh "$release" "$jenkins_uid" "$jenkins_gid"
	done
done

echo aseba-build-linux > /etc/hostname
timedatectl set-timezone Europe/Zurich

systemctl disable init.service
systemctl reboot
