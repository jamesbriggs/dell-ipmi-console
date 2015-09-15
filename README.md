dell-ipmi-console
=================

**Overview**

gocons.pl is a wrapper for ipmitool and Dell IPMI that:

- allows system administrators to remotely manage Dell servers that have IPMI configured using a text console
- stores the IPMI password centrally so that users don't have to type it for each command
- provides commonly-used options to ipmitool for greater ease-of-use and site-wide compatibility
- has comprehensive help.

gocons.pl has been extensively tested on Dell 1950 and 2950 servers.

**Security**

IPMI requires a username and password. Because IPMI credentials tend to be long-lived, they must be protected.

There are several ways on linux to restrict credentials to authorized users:

- only root users: chown root:root gocons; chmod 700 gocons
- for group members: chown root:mygroup gocons; chmod 750 gocons
- store username/password in ENVARIABLES readable only by authorized users: export GOCONS_USER=username; export GOCONS_PASSWORD=password;
- sudo or sudoers
- use setuid (if you have suidperl or a C wrapper): chown root:root gocons; chmod 700 gocons; chmod +s gocons

<pre>
# gocons -h
/usr/local/bin/gocons version 0.6

usage: /usr/local/bin/gocons -h hostname|ip [ -adhpsuv --help --version ]

-a (activate console)
-c (chassis: status, identify, policy list, policy always-on, policy always-off, policy previous, restart_cause, poh, bootdev, bootparam, selftest)
-d (deactivate console)
-h hostname (with MAC address in /etc/ethers or local hash)
-o (lcd status|mac get 0|mac get 1|mac list)
-p (power: on, off, cycle, reset, diag, soft)
-r (print)
-s (SEL: list, clear, info)
-u (display user list)
-v (verbose)
-x (display SDR)
-z (display IPMI hosts hash)
--version
--help

Examples:

/usr/local/bin/gocons -h mercury -s       # display SEL for host mercury
/usr/local/bin/gocons -h mercury -a       # attach SOL for host mercury
/usr/local/bin/gocons -h mercury -d       # detach SOL for host mercury
/usr/local/bin/gocons -h 127.0.0.1 -u -v  # display user list for IP address 127.0.0.1, verbosely
/usr/local/bin/gocons --help              # this help
/usr/local/bin/gocons --version           # this help
</pre>
