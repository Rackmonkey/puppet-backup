# == Class: backup
#
# Full description of class backup here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'backup':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class backup {

  unless $::kernel == 'FreeBSD' {
    fail("This module is only tested on FreeBSD, but you're running ${::kernel}")
  }
  concat{'/etc/ctl.conf':
    ensure  => 'present',
    mode    => '0640',
    notify  => Service['ctld'],
  }
  each(split($::interfaces, ',')) |$interface| {
    unless $interface == 'lo0' {
      $ip = $address = inline_template("<%= scope.lookupvar('::ipaddress_${interface}') -%>")
      concat::fragment{"portal-group-${interface}":
        target  => '/etc/ctl.conf',
        content => "portal-group pg-${interface} {\n  discovery-auth-group no-authentication\n  listen ${ip}\n}\n",
      }
    }
  }
  # enable ctld, needed for iscsi targets
  service{'ctld':
    ensure  => 'running',
    enable  => true,
    require => Concat['/etc/ctl.conf'],
  }
}
