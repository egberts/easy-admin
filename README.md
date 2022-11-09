# easy-admin
These scripts are for easy system administration for a
simple bare minimum server.  These got started within Debian, but soon expanded to include CentOS, Fedora, Redhat, and ArchLinux.  Gentoo and RockyOS is next on my list.

Scripts that would only help white-lab managers; and also to help us bare-metal configurators, test jockeys, cloud virtualizers, network grokkers, and home-bounded computer scientists.

PREMISE: You installed a package using one of those distro package tools. They didn't configure your box correctly or it was barely usable at "basic settings".

SOLUTION: Now we have these bash scripts, that takes you even further in customization.

You run them,
it looks at what kind of OS and network interfaces you have,
it asks you a few questions, warns you of poor choices,
securely writes the configuration files, perfectly so,
and starts your services...

Only the way you dictate them.

* No more accidental security vulnerabilities,
* No network holes,
* No hacked box,
* No more guessing nor remembering settings of many unintelligible keywords.
* often better than (or at a least equal to) CISecurity

Execute script, read and answer the questions; then be up and running.

Some features are:

* Minimum Debian packages
* SCAP/OSCAP settings, default or better
* custom hardened kernel building
* easier systemctl usage
* autoconfigurator for:
  * SSH (OpenSSH)
  * Network managers (`systemd-networkd`, `NetworkManager`, `ifupdown`)
  * DHCP
  * Chrony NTP server/client
  * DNS, ISC Bind9: authoritative, bastion/split-horizon, resolver
  * Shorewall firewall (coming)

Script Nesting
==============
By layering functionality of common environment variables, I was able to easily fold in other Linux distros into the script.

```
    999-custom-easy-admin-scripts.sh
       |
       V
    maintainer-xxx-xxxx.sh
       |
       V
    distro-os.sh
       |
       V
    easy-admin-installer.sh
```

The first script layer is `easy-admin-installer.sh`.  It is extremely similar to `install` tool found in `autotool` but extended to work in `chroot`, `BUILDROOT` and mini private-root filesystem.  Contains no active scripting but mostly contains functions for psuedo emulating `mkdir`, `chown`, `chmod`, `chcon`, and `touch`.

Second script is `distro-os.sh`.  As the filename implies, it deals with quirkiness of each distribution of Linux OS.  Some example of quirks are where to put the `/run` or `/var/run`, and `sudo` or `wheel` group.

Third script is `maintainer-xxx-xxxx.sh`.  Yeah, each maintainer of the software also throw in their own quirks as well such as unique package name, systemd unit service name. `/etc/<what-name-is-that>` configuration subdirectory name, and many many more.

File Permission/Ownership
=========================
Each scripts generates a shell scripts to ensure file permissions and file ownerships of generated configuration files.

Each script prompts system admins on HOW they want their end-users to interact with such tools and actually ensures this.

Also, having a statically-generated shell script that evokes 'chown/chmod/chcon' ensures that nothing gets changed between distros and between package updates.  Meets your QA and Common Criteria too.  You do know that distros do do reset file permissions and ownership (much to system admins' angst).  This is why some distros chosen over others by the serious system administrators.

[![Lint Code Base](https://github.com/egberts/easy-admin/actions/workflows/super-linter.yml/badge.svg)](https://github.com/egberts/easy-admin/actions/workflows/super-linter.yml) [![Codacy Security Scan](https://github.com/egberts/easy-admin/actions/workflows/codacy-analysis.yml/badge.svg)](https://github.com/egberts/easy-admin/actions/workflows/codacy-analysis.yml) 
