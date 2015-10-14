# == Class: backup::params
#
# # This class exists to
# 1. Declutter the default value assignment for class parameters.
# 2. Manage internally used module variables in a central place.
#
# Therefore, many operating system dependent differences (names, paths, ...)
# are addressed in here (if we ever want to support more than FreeBSD).
#
# === Parameters
#
# None
#
# === Variables
#
# None
#
# === Examples
#
# You shall not use this class directly
#
# === Authors
#
# Tim Meusel <tim@bastelfreak.de>
#
# === Copyright
#
# Copyright 2015 Tim Meusel, Kalt Medien UG

class backup::params {
  $allow_ftp   = false # plaintext
  $allow_sftp  = true  # openssh
  $allow_ftps  = false # requires ftp daemon, slow
  $allow_ssh   = false # just meh
  $allow_nfs   = true  # somehow built in
  $allow_iscsi = true  # blockdevice
  $allow_nbd   = true  # blockdevice
}
