# Fail2Ban: Basic set up for an exposed system

## Overview

This is a basic set up for Fail2Ban on an system that is directly exposed to the
internet (i.e. not behind a separate firewall).  In addition to the standard
SSHd jail, a separate jail that monitors UFW BLOCK reports (i.e. connection
attempts to closed ports, etc.) is activated.  This should aid in blocking
'scriptkiddies' and port-scanning attacks, reducing the resources your server
has to allocate to processing bogus requests.  F2B will automatically create UFW
rules to drop connections from systems that try to make repeated invalid
connection attempts and then remove the block automatically after the 'bantime'
has expired.

## Installing an up-to-date Fail2Ban version

The F2B version available via apt for Debian/Ubuntu is old and does *not*
support IP6 (as at the time of this document being written).  So let's grab a
newer version from the source at github.

*Note: Only versions 0.10+ offer IP6 support.*

- Switch to your home directory or somewhere you can work with downloaded files.
- Get the latest version of Fail2Ban, switch to the created directory and
  install it using the python installer script.

  ```Bash
  # get latest fail2ban version
  git clone https://github.com/fail2ban/fail2ban.git
  # change to the newly created directory containing f2b
  cd fail2ban
  # run the installer
  sudo python setup.py install
  ```

- Let's test the installation by running fail2ban-client.  If it displays the
  help screen, then things are probably set up properly.

  ```Bash
  fail2ban-client -h
  ```

- Now, let's configure systemd to load fail2ban automatically on system start-up.

  ```Bash
  # copy the service file to the correct location
  sudo cp files/debian-initd /etc/init.d/fail2ban
  # tell systemd to refresh itself to recognize the new service
  sudo update-rc.d fail2ban defaults
  ```

- Let's go ahead and start the service to make sure it doesn't run into any
  problems.  You shouldn't see any errors reported and should have a pleasant
  'green dot' showing up.

  ```Bash
  # start the service
  sudo systemctl start fail2ban.service
  # check it's status for any errors
  sudo systemctl status fail2ban.service
  ```

- One more test just to be sure everything is set up.  You should see f2b report
  it's version without any errors being generated.

  ```Bash
  fail2ban-client version
  ```

## Customizing your set up

