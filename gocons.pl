#!/usr/bin/perl

# Program: gocons.pl
# Purpose: ipmitool wrapper
# Licence: GPL2
# Copyright 2013 James Briggs, San Jose, California, USA.
# Date: 2013 07 04
# Note: ln -s /usr/local/bin/gocons.pl /usr/local/bin/gocons

use strict;
use diagnostics;

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

#   $ENV{'PATH'} = '';

   my $VERSION = '0.5';

# customize here ...
   my $DEBUG = 0;
   my $username = 'root' || 'ADMIN';
   my $password = '';

   # Since IPMI interfaces are often out-of-band compared to regular DNS ...
   # we need a directory of IPMI hosts or IPs with MAC and IP address

   my %ipmi_hosts = ( # directory of IPMI hosts with MAC and IP address
#      'sample1-ipmi'       => [ undef, '127.0.0.1' ], # no MAC, so check /etc/ethers
#      'sample1-ipmi.fq.dn' => [ '00:00:00:00:00:00', '127.0.0.1' ],
#      '127.0.0.1'     => [ qw[00:00:00:00:00:00 127.0.0.1] ],
   );

   my $cmd_ipmi    = '/usr/bin/ipmitool';
   my $ethers_file = '/etc/ethers';

# initialization and validation here ...
   my $prog = $0;

   for my $host (keys %ipmi_hosts) { # add reversed entries for IP -> MAC lookups
       $ipmi_hosts{$ipmi_hosts{$host}->[1]} = $ipmi_hosts{$host} if not exists $ipmi_hosts{$ipmi_hosts{$host}->[1]};
   }

   our ($opt_a, $opt_c, $opt_d, $opt_h, $opt_o, $opt_p, $opt_r, $opt_s, $opt_u, $opt_v, $opt_x, $opt_z);
   getopts('ac:dh:o:p:rs:uvxz');

   my ($o_activate, $o_chassis, $o_deactivate, $o_delloem, $o_host, $o_power, $o_print, $o_sdr, $o_sel, $o_users, $o_verbose, $o_ethers);

   if ($opt_z) {
      for my $host (sort keys %ipmi_hosts) {
          print sprintf("%17s %s\n", defined $ipmi_hosts{$host}->[0] ? $ipmi_hosts{$host}->[0] : '', $host);
      }
      exit;
   }

   $o_activate   = $opt_a; # SOL

   $o_chassis    = $opt_c;
   if (defined $o_chassis) {
      $o_chassis = lc $o_chassis;
      $o_chassis =~ s/"'//g;
      usage() if $o_chassis !~ /^(status|power|identify|policy list|policy always-on|policy always-off|policy previous|restart_cause|poh|bootdev|bootparam|selftest)$/;
   }

   $o_delloem    = $opt_o;
   if (defined $o_delloem) {
      $o_delloem = lc $o_delloem;
      $o_delloem =~ s/"'//g;
      usage() if $o_delloem !~ /^(lcd status|mac get 0|mac get 1|mac list)$/;
   }

   $o_deactivate = $opt_d; # SOL

   $o_host       = $opt_h; # hostname or IP address
   if (defined $o_host) {
      $o_host = lc $o_host;
      $o_host =~ s/[^a-z0-9._-]//g;
   }
   else {
      usage();
   }

   $o_power      = $opt_p;
   if (defined $o_power) {
      $o_power = lc $o_power;
      usage() if $o_power !~ /^(on|off|cycle|status|reset|diag|soft)$/;
   }

   $o_print      = $opt_r;

   $o_sel        = $opt_s; # SEL
   if (defined $o_sel) {
      $o_sel = lc $o_sel;
      usage() if $o_sel !~ /^(list|clear|info)$/;
   }

   $o_users      = $opt_u; # user list

   $o_verbose    = $opt_v;

   $o_sdr        = $opt_x; # SDR
 
   my ($mac, $ip);
   ($mac, $ip) = @{$ipmi_hosts{$o_host}} if exists $ipmi_hosts{$o_host};

   # 411 - a common cause of IPMI connection failure is missing MAC in ARP table
   if (defined $ip and not defined $mac) {
      my $flag = 1;
      open(my $ethers_fh, '<', $ethers_file) || do { $flag = 0; print "warning: can't open $ethers_file: $!\n"};
      if ($flag) {
         while (<$ethers_fh>) {
            if (/^([a-f0-9:]{17})\W+$ip/i) {
               $mac = $1;
               last;
            }
         }
      }
      
      print "warning: MAC not defined for $ip. Trying to connect anyway ...\n" if not defined $mac;
   }
   elsif (not defined $ip) {
      $ip = $o_host;
   }

   my $cmd = '';
   my $msg = '';

# action here ...

   if ($o_activate) {
      $cmd = "$cmd_ipmi -I lanplus -H $ip -U $username -P $password sol activate";
      $msg = 'Press ~. to terminate session.';
   }
   elsif ($o_chassis) {
      $cmd = "$cmd_ipmi -H $ip -U $username -P $password chassis $o_chassis";
   }
   elsif ($o_deactivate) {
      $cmd = "$cmd_ipmi -I lanplus -H $ip -U $username -P $password sol deactivate";
   }
   elsif ($o_delloem) {
      $cmd = "$cmd_ipmi -H $ip -U $username -P $password delloem $o_delloem";
   }
   elsif ($o_power) {
      $cmd = "$cmd_ipmi -H $ip -U $username -P $password power $o_power";
   }
   elsif ($o_print) {
      $cmd = "$cmd_ipmi lan -H $ip -U $username -P $password print";
   }
   elsif ($o_sel) {
      $cmd = "$cmd_ipmi -H $ip -U $username -P $password sel $o_sel";
   }
   elsif ($o_users) {
      $cmd = "$cmd_ipmi -H $ip -U $username -P $password user list";
   }
   elsif ($o_sdr) {
      $cmd = "$cmd_ipmi -H $ip -U $username -P $password sdr";
   }
   else {
      usage();
   }

   if ($o_verbose) {
      my $s = $cmd;
      $s =~ s/$password/xxxxxx/g if $password ne '';
      print "cmd=$s\n";
   }

   if (!$DEBUG) {
      ### my $r = `$cmd`;
      ### print "host $o_host: $r";
      my @args = split(/ +/, $cmd);
      print "$msg\n" if $msg ne '';
      system(@args) == 0 or die "system @args failed: $?"
   }

sub usage {
   print <<EOD;
$prog version $VERSION

usage: $prog -h hostname|ip [ -adhpsuv --help --version ]

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

$prog -h mercury -s       # display SEL for host mercury
$prog -h mercury -a       # attach SOL for host mercury
$prog -h mercury -d       # detach SOL for host mercury
$prog -h 127.0.0.1 -u -v  # display user list for IP address 127.0.0.1, verbosely
$prog --help              # this help
$prog --version           # this help
EOD

   exit;
}

sub HELP_MESSAGE
{
   usage();
}

sub VERSION_MESSAGE
{
   usage();
}

