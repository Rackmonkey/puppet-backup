# == Class: backup::scp
#
# # This class exists to
# 1. manage everything that is related to scp access
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

class backup::scp {
  package {'rssh':
    ensure  => present,
  }
}
