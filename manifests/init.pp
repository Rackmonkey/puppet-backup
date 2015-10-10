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
#  include ::backup
#  backup::account{'user1':
#    type            => 'ssh',
#    zfs_settings    => {
#      compression => 'on',
#      quota       => '100G',
#    },  
#    # mkpasswd -m sha-512 on debian
#    user_settings   => {
#      shell     => '/usr/sbin/nologin',
#      password  => '$6$tghjkiutrf$xcferutoiunbztrcexctvjzubkilunkzjthrxextcrtbzu',
#    },  
#    ssh_key => 'ssh-ed25519 w4ztiuterexkcrvrthgjfedvtbjkzukiiujvhct',
#  }
#
# === Authors

#
# === Authors
#
# Tim Meusel <tim@bastelfreak.de>
#
# === Copyright
#
# Copyright 2015 Tim Meusel, Kalt Medien UG
#
class backup (
  $allow_ftp    = true,
  $allow_sftp   = true,
  $allow_ftps   = true,
  $allow_ssh    = true,
  $allow_iscsi  = true,
  $allow_nbd    = true,
  $allow_nfs    = true,
){

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
  group{'customers':
    ensure  => present,
  }
  if $allow_sftp {
    # todo: implement this dynamically and don't hardcode the group
    $group = 'group customers'
    Sshd_config{
      condition => $group,
      require   => Sshd_config_match[$group],
    }
    sshd_config_match {$group:
      ensure => present,
    }
    sshd_config{'ChrootDirectory':
      key   =>  'ChrootDirectory',
      value => '/customers/%u',
    }
    sshd_config{'X11Forwarding':
      key   => 'X11Forwarding',
      value => 'no',
    }
    sshd_config{'AllowTcpForwarding':
      key   => 'AllowTcpForwarding',
      value => 'no',
    }
    sshd_config{'ForceCommand':
      key   => 'ForceCommand',
      value => 'internal-sftp',
    }
    sshd_config{'AuthorizedKeysFile':
      key   => 'AuthorizedKeysFile',
      value => '/etc/ssh/login-keys/%u.keys',
    }
  }
}
