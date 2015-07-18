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
# Tim Meusel <tim@bastelfreak.de>
#
# === Copyright
#
# Copyright 2015 Tim Meusel, unless otherwise noted.
#
define backup::account (
  String[3]                           $user       = $title,
  Boolean                             $compression  = true,
  Boolean                             $dedup        = false,
  Enum['nfs', 'iscsi', 'nbd', 'file'] $access_type  = 'file',
  String[12]                          $password,
  String[2]                           $quota,
  Array                               $allow_ipv4,
  Array                               $allow_ipv6,
  Array                               $deny_ipv4.
  Array                               $deny_ipv6,
) { }
