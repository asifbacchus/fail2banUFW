# Fail2Ban: Basic set up for an exposed system <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [Overview](#overview)
- [Installing an up-to-date Fail2Ban version](#installing-an-up-to-date-fail2ban-version)
- [Customizing your set up](#customizing-your-set-up)
  - [/etc/fail2ban/fail2ban.conf](#etcfail2banfail2banconf)
    - [loglevel](#loglevel)
    - [logtarget](#logtarget)
    - [dbpurgeage](#dbpurgeage)
  - [/etc/fail2ban/jail.local](#etcfail2banjaillocal)
    - [ignoreip](#ignoreip)
    - [Timeframes](#timeframes)
    - [Actions](#actions)
      - [Notication options](#notication-options)
      - [Shortcuts](#shortcuts)
- [Jails](#jails)
  - [sshd (/etc/fail2ban/jail.d/ssh.conf)](#sshd-etcfail2banjaildsshconf)
  - [UFW port probing](#ufw-port-probing)
    - [Name of the jail](#name-of-the-jail)
    - [Ports and IPs](#ports-and-ips)
    - [Timeframes](#timeframes)
    - [Jail-specific settings](#jail-specific-settings)
- [The UFW filter regex (/etc/fail2ban/filter.d/ufw-probe.conf)](#the-ufw-filter-regex-etcfail2banfilterdufw-probeconf)
- [The action file (/etc/fail2ban/action.d/ufw.conf)](#the-action-file-etcfail2banactiondufwconf)
- [Repeat offenders](#repeat-offenders)
  - [Apply the extended ban via iptables directly](#apply-the-extended-ban-via-iptables-directly)
- [Final thoughts](#final-thoughts)

## Overview

This is a basic set up for Fail2Ban on an system that is directly exposed to the
internet (i.e. not behind a separate firewall).

**This set-up assumes you are using UFW as your firewall front-end and it is
working correctly.**

In addition to the standard SSHd jail, a separate jail that monitors UFW BLOCK
reports (i.e. connection attempts to closed ports, etc.) is activated.  This
should aid in blocking 'scriptkiddies' and port-scanning attacks, reducing the
resources your server has to allocate to processing bogus requests.  F2B will
automatically create UFW rules to drop connections from systems that try to make
repeated invalid connection attempts and then remove the block automatically
after the 'bantime' has expired.

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
  problems.  You should not see any errors reported and should have a pleasant
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

As with all Fail2Ban setups, you should do all your customization in the
*.local* files and not the .conf files since those may be overwritten by
updates.

### /etc/fail2ban/fail2ban.conf

I recommend reviewing the following settings at a minimum for any deployment:

#### loglevel

This sets the verbosity of the log output from F2B.  The default setting of INFO
is appropriate for most installs but, you should specify it anyway so you have
an easy place to change it if you need to do so.

```Ini
loglevel = INFO
```

#### logtarget

This controls the location of the F2B log file where it logs it's own actions.
This is NOT the location of the log files it reads for banning!  Again, the
default is appropriate for most installs, but you should specify it in your
custom configuration so you have an easy place to change it if needed.

```Ini
logtarget = /var/log/fail2ban.log
```

#### dbpurgeage

This controls how long F2B keeps a record of systems it has banned for whatever
reason.  By default, this is set to one day. I prefer having a one week record
so I can go back and review as necessary.  You can set it to whatever you want,
duration is expressed in *seconds*.

```Ini
dbpurgeage = 604800
```

### /etc/fail2ban/jail.local

This file customizes the defaults applied to all jail configurations used by F2B.
This sets things like the default amount of time a system is banned, what
actions should be used for banning systems and whether or not you get email
notifications, etc.

#### ignoreip

This setting tells F2B which IP addresses/ranges/hostnames should **never** be
banned.  In general, this should be the localhost only.  However, if you connect
by remote using a particular machine, you might also want to exempt it from any
possible bans.  You can specify more than one entry by separating them with a
space or comma.  In this case, I've added the IP4 and IP6 defintions for
localhost.

```Ini
ignoreip = 127.0.0.1/8 ::1
```

#### Timeframes

You should customize the relevant timeframes to your requirements and this will
likely take a little experimentation.  F2B checks for a system making '*maxretry*'
failed attempts to connect or login within '*findtime*' seconds and, if that
happens, bans the system for '*bantime*' seconds.

I like using settings as below which state, "ban any system for 30 minutes that
makes 5 invalid connection attempts within a 5 minute period".

```Ini
bantime = 1800
maxretry = 5
findtime = 300
```

Some people find this too aggressive and prefer settings such as 10 attempts in
20 minutes, for example, which would look like:

```Ini
bantime = 1800
maxretry = 10
findtime = 1200
```

Again, this will be up to you to determine what is appropriate for your
environment and users.  Remember that invididual jails can override these
defaults.

#### Actions

##### Notication options

If you choose actions that involve sending email notifications, you need to let
F2B know where to send those emails and who should send them.  It's pretty
straightforward, so this is the general setup:

```Ini
destemail = account@domain.tld
sender = thismachine@domain.tld
mta = sendmail
```

The '*mta*' field is very likely correct for your system but, if you are using a
different MTA, you'll want to specify that here.

##### Shortcuts

This is where you tell F2B exactly what to do when it finds a reason to ban a
system based on the jail configuration.  Again, individual jails can override
these settings.  The settings are defined backwards in this file, so I'll take a
second to explain.

'*action*' is performed each time a system should be banned.  There are several
predefined actions listed in the /etc/fail2ban/jail.conf file which you can use
and are often sufficient for most setups.  Read the comments in that file to
understand what each predefined action does.  In my case, I like getting an
email along with a few lines from the log telling me what they did to get
banned.

Within '*action*' is '*banaction*' which is a link over to a specific
configuration file telling F2B what to do on the system to enforce the ban.  In
this setup, we direct F2B to look at the ufw.conf file to see how to modify
UFW's rules so it drops packets from the offending system.  [Details on that
file are found later in this
document](#The-action-file-(/etc/fail2ban/action.d/ufw.conf)).

The general setup as described above is as follows:

```Ini
banaction = ufw
action = %(action_mwl)s
```

## Jails

F2B uses '*jail configurations*' specified either in */etc/fail2ban/jail.conf*,
*/etc/fail2ban/jail.local* or in */etc/fail2ban/jail.d/*.  The latter is my
preference since it allows for each jail to be contained in it's own
configuration file which makes debugging and maintaining them much easier.

### sshd (/etc/fail2ban/jail.d/ssh.conf)

I usually just define a basic jail for *sshd* which is the SSH server.  You can
add additional SSH jails as you wish to this file, but I keep it pretty simple.
One note, I run my SSH server on a non-standard port, so be sure you fill in the
correct port for your environment such as my example below of port 222:

```Ini
[sshd]
port    = 222
...
```

If you are running on the standard port 22, then you can actually omit this line
entirely since it's already defined in the default .conf files.  Also note that
if you have customized your SSHd configuration to use non-standard logging,
you'll want to specify a logfile location in the jail also, like this:

```Ini
[sshd]
...
logpath     = /path/to/your/log.file
...
```

### UFW port probing

This is probably the part you are really looking for in this entire set-up.  We
will create a custom jail that monitors UFW's logs for any mention of *[UFW
BLOCK]* and then proceeds to ban those systems attempting to connect to blocked
ports as per your timeframe settings.  I've commented the ufw-probe file but
I'll run though it here also for convenience.

#### Name of the jail

You can call this anything that has meaning to you, I've chosen '*ufw-probe*'.
Just change what it says in the [square brackets]

```Ini
[ufw-probe]
...
```

#### Ports and IPs

Since this is searching for port probing, we will tell F2B to look for attempts
made to connect to any and all ports.  **The '*ignoreip*' parameter is only
necessary IF it's different from what you've already set in '*jail.local*'.**

```Ini
port        = all
ignoreip    = 127.0.0.1/8 ::1
```

#### Timeframes

This section is also optional and is only needed if it's different from what you
have in your '*jail.local*'.  I like keeping it in this configuration file
though since the settings for this jail are often different from others.

```Ini
maxretry    = 5
findtime    = 300
```

#### Jail-specific settings

In order for this jail to function, you need to give F2B a little information.
First, we need to specify what log file it should be parsing.  In this case,
it's the UFW log file which is, by default, located at */var/log/ufw.log*.  If
you've changed this, then update the '*logpath*' parameter.  We also need to
tell it what filter to use when parsing the file, in this case, it's a filter
I've called 'ufw-probe' (change this if you change the filename) which is
located at */etc/fail2ban/filter.d/ufw-probe.conf* [(details here)](#The-UFW-filter-regex-(/etc/fail2ban/filter.d/ufw-probe.conf)).  Finally, we
tell F2B to enable this jail.

```Ini
logpath     = /var/log/ufw.log
filter      = ufw-probe
enabled     = true
```

## The UFW filter regex (/etc/fail2ban/filter.d/ufw-probe.conf)

When F2B is parsing *ufw.log*, it has to be told what entry denotes a failure
and increments the retry counter toward a ban.  This is done via a regular
expression (REGEX):

```PHP
.*\[UFW BLOCK\] IN=.* SRC=<HOST>
```

Specifically, this matches any line containing '*[UFW BLOCK]*' and includes the
source IP address '*<HOST>*'

## The action file (/etc/fail2ban/action.d/ufw.conf)

This is the file that tells F2B what commands to send to UFW to block and
unblock a system.  If you downloaded a fairly recent version of F2B, then you
should already have this file.  If not, you can copy the one in this git.

You can see that the '*actionban*' and '*actionunban*' sections simply add and
remove rules from UFW which drop/reject packets from the offending system.  I
have only changed the '*blocktype*' from it's default (reject) to *deny*.

```Ini
# Option: blocktype
# Notes.: reject or deny
#blocktype = reject
blocktype = deny
```

The important part of '*actionban*' works like this:

```PHP
ufw insert <insertpos> <blocktype> from <ip> to <destination>
```

The variables defined in the configuration file are summarized as:

```Ini
[Init]
insertpos = 1
blocktype = deny
destination = any
application =
```

So, this rule adds a new rule (*insert*) at position 1 (*insertpos*) which
denies (*blocktype*) packets from the offending system's IP (*ip*) destined for
any address (which obviously includes this system).  Importantly, each rule is
added at *position 1* which means they have priority over any other
otherwise defined (i.e. allowed) traffic.

The '*actionunban*' simply deletes the rule to remove the block.

## Repeat offenders

In some cases, the same systems will continue probing your system even after
being banned several times.  I choose to call these '*recidivists*' and setup a
special jail for them.

The *recidivist jail* scans the *fail2ban* log to search for systems that have
been issued a certain threshold number of bans already.  If any are found, they
are issued a longer-term ban.  Let's go though the configuration:

The beginning of the file should already be familiar to you along with the fact
that the '*ignoreip*' parameter is optional.

Remember that we are searching for repeat offenders.  In other words, they have
already been issued a ban by F2B so their IP will already appear in F2B's log,
which is why we are searching that file.

```Ini
logpath   = /var/log/fail2ban.log
```

Timeframes here present a bit of a twist in thinking.  In this case,
'*maxretry*' refers to how many previous bans have been issued in '*findtime*'
period.

```Ini
maxretry    = 3
findtime    = 86400
```

In this example, I'm saying that if a particular host has already been banned 3
times in the last 24 hours (86400 seconds), then they need to be put in this
jail!  You should adjust these values to reflect your tolerance levels for
repeat offenders.  **Note: The '*dbpurgeage*' you specified in your
*/etc/fail2ban/fail2ban.conf* file must be at least as long as your '*findtime*'
parameter here so there's enough history for F2B to review!**

The entire point of this jail is to levy longer bantimes than ordinary jails
which generally use the default set in '*/etc/fail2ban/jail.conf*'.
Therefore, we explictly specify a time here, 3 days in this case:

```Ini
bantime     = 259200
```

Finally, we need to let F2B know what filter to use when parsing it's own log
file. We'll use the *recidive* filter provided by F2B for exactly this purpose.
Since we are calling this filter from a jail with a different name (i.e. the
jail is not also called 'recidive'), we have to make that clear to the filter.
Finally, we also enable the jail.

```Ini
filter      = recidive[_jailname="recidivist"]
enabled     = true
```
### Apply the extended ban via iptables directly

You'll notice that the '*recidivist*' jail configuration contains the following
line:

```Ini
banaction   = iptables-allports
```

This means that the ban is generated by creating a rule directly applied to your
iptables configuration and **not** through UFW.  This is because UFW has no
facility to tag or otherwise distinguish rules apart from their index number.
As such, it's possible for the *UFW-probe* jail **unban** process to erase the
longer-term *recidivist* ban and vice versa.  To avoid this conflict, we have
the longer-term rule apply to iptables directly as a separate rule so UFW-probe
can ban/unban independently as needed without any risk of conflicts.

## Final thoughts

Well, that's it.  Fail2Ban will now monitor SSH intrusion attempts and will also
search the logs for any systems that try to connect to blocked ports looking for
an entry vector into your system.  It will then block those systems
automatically for whatever timeframe you specify and then remove that block.  So
you don't have to maintain IP block/allow lists manually anymore!

I hope this helps you in dealing with your server getting bombarded by
irritating scanning-bots.  As always, [check out my blog at
https://mytechiethoughts.com](https://mytechiethoughts.com) for more solutions
like this and feel free to contribute comments, suggestions and improvements!