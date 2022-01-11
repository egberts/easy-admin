# easy-admin
These scripts are for easy Debian (and some Redhat) system administration for a
simple bare minimum server.

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
** DHCP
** Chrony NTP server/client
** DNS, ISC Bind9: authoritative, bastion/split-horizon, resolver


[![Lint Code Base](https://github.com/egberts/easy-admin/actions/workflows/super-linter.yml/badge.svg)](https://github.com/egberts/easy-admin/actions/workflows/super-linter.yml) [![Codacy Security Scan](https://github.com/egberts/easy-admin/actions/workflows/codacy-analysis.yml/badge.svg)](https://github.com/egberts/easy-admin/actions/workflows/codacy-analysis.yml) 
