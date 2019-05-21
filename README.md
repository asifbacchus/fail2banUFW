# Fail2Ban: Block port probes on an exposed system <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [Overview](#overview)
- [Documentation](#documentation)
- [Getting set up](#getting-set-up)
  - [Manual setup](#manual-setup)
  - [Undoing changes](#undoing-changes)
- [Final thoughts](#final-thoughts)

## Overview

This is a basic set up for Fail2Ban on an system that is directly exposed to the
internet (i.e. not behind a separate firewall).

**This set-up assumes you are using UFW as your firewall front-end and it is
working correctly.**

In addition to the standard SSHd jail, a separate jail that monitors UFW BLOCK
reports (i.e. connection attempts to closed ports, etc.) is activated.  This
should aid in blocking 'script-kiddies' and port-scanning attacks, reducing the
resources your server has to allocate to processing bogus requests.  F2B will
automatically create UFW rules to drop connections from systems that try to make
repeated invalid connection attempts and then remove the block automatically
after the 'bantime' has expired.  A special jail is also created for repeat offenders with much longer bantimes as an option.

## Documentation

Please consult the wiki for this repo for detailed instructions, explanations and reasoning behind every customization that is included in the configuration files in this repo.  For a quick-start, just use this readme.  More details can also be found on [my blog](https://mytechiethoughts.com).  Also, all the configuration files are commented so you can just read those if you're already familiar with how F2B works.

## Getting set up

If you need help getting Fail2Ban installed before using this repo to customize it, please see [this wiki post](https://git.asifbacchus.app/asif/fail2banUFW/wiki/02.-Installing-Fail2Ban)

Setup is very simple, especially using the included convenience script which will take care of backing up your existing configuration and copying customized files to the proper locations for you.

  1. Clone this repository or download a release.
  2. Switch to the repo directory and run the *f2b-config.sh* as ROOT or via SUDO.

  ```bash
  cd fail2banUFW

  # as root
  ./f2b-config.sh

  # using sudo
  sudo ./f2b-config.sh
  ```

If you're fail2ban configuration files are located somewhere other than */etc/fail2ban/* then you can pass that location to the script as a parameter.  Let's assume */opt/fail2ban/* for this example (trailing slash is optional):

```bash
./f2b-config.sh /opt/fail2ban/
```

### Manual setup

If you don't want to use the script, then you don't have to!  The repo uses the same directory structure as a default Fail2Ban installation on Debian/Ubuntu so you can just copy the files you want to their proper locations.

### Undoing changes

If you want to undo the changes made by the convenience script, just find the affected files and copy the backups over the current files.  For example, to restore your *jail.local* file:

```bash
cp /etc/fail2ban/jail.local.original /etc/fail2ban/jail.local
```

## Final thoughts

I hope this helps you in dealing with your server getting bombarded by
irritating scanning-bots.  As always, [check out my blog at
https://mytechiethoughts.com](https://mytechiethoughts.com) for more solutions
like this and feel free to contribute comments, suggestions and improvements!

If you find any bugs, want to make suggestions or have a better idea of how to set things up, feel free to post an issue, please!