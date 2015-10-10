class backup::scp {
  package {'rssh':
    ensure  => present,
  }
}
