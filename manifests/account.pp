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
  $homepath       = '/customers',
  $user_settings  = '',
  $zfs_settings   = '',
  $iscsi_settings = '',
  $allow_ipv4     = '',
  $allow_ipv6     = '',
  $deny_ipv4      = '',
  $deny_ipv6      = '',
  $ensure         = 'present',
  $zpool          = 'zroot', #default on FreeBSD
  $mode           = '0750',
  $group          = $title,
  $type           = 'iscsi',
  $ssh_key        = undef,
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
    $user_settings2 = merge({'home' => $home, 'groups' => 'customers', require => Group['customers'], purge_ssh_keys => true}, $user_settings)
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
      owner => 'root',
      group => $group,
      mode  => $mode,
    }
  }
  if $type != ['iscsi', 'nbd'] {
    if $ssh_key {
      # we need to place the key in the subdir and not in $home because the user hasn't write access there
      $ssh_key_array = split($ssh_key, ' ')
      ssh_authorized_key{"ssh_authorized_key-${title}":
        user    => $title,
        type    => $ssh_key_array[0],
        key     => $ssh_key_array[1],
        target  => "/customers/${title}/${title}/.ssh/authorized_keys",
      }
    }
  }
  case $type {
    'iscsi':  { if $backup::allow_iscsi {include backup::iscsi} else {fail("your provided type ${type} isn't allowed on this server")}}
    'ftp' :   { if $backup::allow_ftp   {include backup::ftp} else {fail("your provided type ${type} isn't allowed on this server")} }
    'sftp':   { if $backup::allow_sftp  {include backup::ftp} else {fail("your provided type ${type} isn't allowed on this server")}}
    'ftps':   { if $backup::allow_ftps  {include backup::ftps} else {fail("your provided type ${type} isn't allowed on this server")}}
    'ssh':    { if $backup::allow_ssh   {include backup::ssh} else {fail("your provided type ${type} isn't allowed on this server")}}
    'nbd':    { if $backup::allow_nbd   {include backup::nbd} else {fail("your provided type ${type} isn't allowed on this server")}}
    'nfs':    { if $backup::allow_nfs   {include backup::nfs} else {fail("your provided type ${type} isn't allowed on this server")}}
    default:  { fail("your provided type ${type} isn't available in this module")}
  }
}
