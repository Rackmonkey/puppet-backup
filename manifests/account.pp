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
# preparation for puppet 4
#  String[3] $homepath,
#  Hash $user_settings,
#  Hash $zfs_settings,
#  Array $allow_ipv4,
#  Array $allow_ipv6,
#  Array $deny_ipv4.
#  Array $deny_ipv6,
#  Enum['present', 'absent'] $ensure = 'present',
#  String[3] $zpool = 'zroot', #default on FreeBSD
#  String[4] $mode = '0770',
#  String[1] $group = $title,
  $homepath       = '',
  $user_settings  = '',
  $zfs_settings   = '',
  $iscsi_settings = '',
  $allow_ipv4     = '',
  $allow_ipv6     = '',
  $deny_ipv4      = '',
  $deny_ipv6      = '',
  $ensure         = 'present',
  $zpool          = 'zroot', #default on FreeBSD
  $mode           = '0770',
  $group          = $title,
  $type           = 'iscsi',
) {
  $home = "${homepath}/${title}"

  if $type == 'iscsi' {
    $zfs_settings2 = $zfs_settings
    $iqn = join(reverse(split($::fqdn, '\.')), '.')
    concat::fragment{"auth-group-${title}":
      target  => '/etc/ctl.conf',
      content => "auth-group ag-${title} { chap ${title} ${user_settings['password']} }\n",
    }
    concat::fragment{"target-${title}":
      target  => '/etc/ctl.conf',
      content => "target iqn.2012-06.${iqn}:${title} {\n  auth-group ag-${title} \n  portal-group ${iscsi_settings['pg']} \n  lun 0{\n    path /dev/zvol/${zpool}/${title} \n    backend block\n  }\n}",
    }
  } else {
    $zfs_settings2 = merge({'mountpoint' => $home}, $zfs_settings)
  }

  unless defined(User[$title]) {
    $user_settings2 = merge({'home' => $home}, $user_settings)
    if (has_key($user_settings, 'ensure')){
      $user_settings3 = $user_settings2
    } else {
      $user_settings3 = merge({'ensure' => $ensure}, $user_settings2)
    }
    $user_params = {"${title}" => $user_settings3}
    create_resources(user, $user_params)
  }

  if (has_key($zfs_settings, 'ensure')){
    $zfs_settings3 = $zfs_settings2
  } else {
    $zfs_settings3 = merge({'ensure' => $ensure}, $zfs_settings2)
  }
  $zfs_settings4 = { "${zpool}/${title}" => $zfs_settings3}
  create_resources(zfs, $zfs_settings4)

  unless $ensure == 'absent' {
    file{$home:
      owner => $title,
      group => $group,
      mode  => $mode,
    }
  }
}
