Built for Personal Use Only

![archNAS-logo](https://github.com/Pheoxy/ArchNAS/raw/0.1/boot/archNAS-logo.png)
# archNAS

archNAS is intended for high customizeabilty and use of the archlinux distro.

archNAS uses scripts from the Arch Linux Anywhere Project.
Kudos to them!

http://arch-anywhere.org/


### Features:

### Future Features:

* WebUI

    [Cockpit](http://cockpit-project.org/) <br />

* Containers

    [Docker](https://www.docker.com/) <br />

* Network Sharing

    FTP <br />
    SMB/CIFS <br />
    NFS <br />
    TFTP <br />
    Rsync <br />

* Terminal

    SSH/SFTP <br />

### Install:

Go through the installer and install archNAS.

Once you have booted login as `root` and enter these commands to install <b>cockpit</b>.

`cd /tmp`

`git clone https://aur.archlinux.org/cockpit.git`

`tar -xvf cockpit.tar.gz`

`cd cockpit`

Check for errors:

`nano PKGBUILD`

`nano cockpit.install`

`makepkg -sri`

`systemctl start cockpit.service`

`systemctl enable cockpit.service`

You can access cockpit WebUI at:

`https://ip-address-of-machine:9090`

Now we need to install <b>docker</b>

`pacman -S docker`

`systemctl start docker.service`

`systemctl enable docker.service`

`docker info`

If you want to be able to run docker as a regular user, add yourself to the docker group:

`gpasswd -a user docker`

`newgrp docker`

And where done enjoy your new archNAS system!