# This module has been tested on FreeBSD 10 only
class postfix_freebsd (
  $service = 'postfix',
  $package = 'postfix', # Maybe you should build postfix from ports with all options you want first
  $ensure = present,
  $config_dir = '/usr/local/etc/postfix',
  $mailer_config_template = 'postfix_freebsd/mailer.conf.erb',
  $mailer_config_manage = true,
  $mailer_config = {
    sendmail   => '/usr/local/sbin/sendmail',
    send-mail  => '/usr/local/sbin/sendmail',
    mailq      => '/usr/local/sbin/sendmail',
    newaliases => '/usr/local/sbin/sendmail',
  },
  $postfix_config_template = 'postfix_freebsd/main.cf.erb',
  $postfix_config_manage = false,
  $postfix_config = { },
  $master_config_template = 'postfix_freebsd/master.cf.erb',
  $master_config_manage = false,
  $master_config = { },
  $virtual_config_manage = false,
  $virtual_config = [ ],
  $aliases_config_manage = false,
  $aliases_config = [ ],
  $transport_config_manage = false,
  $transport_config = [ ],
  $header_checks_manage = false,
  $header_checks_source = 'puppet:///files/postfix/header_checks',
  $goodies_manage = false,
  $sasl_manage = true,
  $sasl_type = 'dovecot',
  $tls_manage = false,
  $tls_has_ca = false,
  $tls_config = {
    smtpd_tls_cert_file => '/usr/local/etc/ssl-certs/ssl.crt',
    smtpd_tls_key_file => '/usr/local/etc/ssl-certs/ssl.key',
    smtpd_tls_CAfile => '/usr/local/etc/ssl-certs/ca.pem',
  },
  $mailbox_command_use = true,
  $mailbox_command = '/usr/local/bin/procmail -a "$EXTENSION"',
) {
  File {
    owner => root,
    group => $root_group,
    mode  => '0644',
  }

  case $ensure {
    'running': {
      $ensure_package = present
      $ensure_file = present
      $ensure_directory = directory
      $ensure_service = running
      $ensure_enabled = enabled
      $service_enable = true
    }
    'stopped': {
      $ensure_package = present
      $ensure_file = present
      $ensure_directory = directory
      $ensure_service = stopped
      $service_enable = false
    }
    'present': {
      $ensure_package = present
      $ensure_file = present
      $ensure_directory = directory
      $ensure_service = stopped
      $service_enable = false
    }
    'absent': {
      $ensure_package = absent
      $ensure_file = absent
      $ensure_directory = absent
      $ensure_service = stopped
      $service_enable = false
    }
  }

  package { $package:
    ensure => $ensure_package
  }

  if $goodies_manage {
    package { [
      'procmail',
      'mutt',
      'gnupg',
    ]:
      ensure => $ensure_package
    }
  }

  if $mailer_config_manage {
    file { '/etc/mail/mailer.conf':
      ensure => $ensure_file,
      content => template($mailer_config_template),
    }
  }

  if $postfix_config_manage {
    file { "${config_dir}/main.cf":
      ensure  => $ensure_file,
      content => template($postfix_config_template),

      require => Package[$package],
      notify  => Service[$service],
    }
  }

  if $master_config_manage {
    file { "${config_dir}/master.cf":
      ensure  => $ensure_file,
      content => template($master_config_template),

      require => Package[$package],
      notify  => Service[$service],
    }
  }

  if $virtual_config_manage {
    file { "${config_dir}/virtual":
      ensure  => $ensure_file,
      content => template('postfix_freebsd/virtual.erb'),

      require => Package[$package],
    }

    exec { "/usr/local/sbin/postmap ${config_dir}/virtual":
      refreshonly => true,

      require   => File["${config_dir}/virtual"],
      subscribe => File["${config_dir}/virtual"],
    }
  }

  if $aliases_config_manage {
    file { "${config_dir}/aliases":
      ensure  => $ensure_file,
      content => template('postfix_freebsd/aliases.erb'),

      require => Package[$package],
    }

    exec { "/usr/local/bin/newaliases":
      refreshonly => true,

      require   => File["${config_dir}/aliases"],
      subscribe => File["${config_dir}/aliases"],
    }
  }

  if $transport_config_manage {
    file { "${config_dir}/transport":
      ensure  => $ensure_file,
      content => template('postfix_freebsd/transport.erb'),

      require => Package[$package],
    }

    exec { "/usr/local/sbin/postmap ${config_dir}/transport":
      refreshonly => true,

      require   => File["${config_dir}/transport"],
      subscribe => File["${config_dir}/transport"],
    }
  }

  if $header_checks_manage {
    file { "${config_dir}/header_checks":
      ensure  => $ensure_file,
      source  => $header_checks_source,

      require => Package[$package],
      notify  => Service[$service],
    }
  }

  service { $service:
    enable  => $service_enable,
    ensure  => $ensure_service,

    require => [
      Package[$package],
      File['/etc/mail/mailer.conf'],
    ],
  }

  #  freebsd::rc_enable { 'postfix':
  #  ensure => $ensure,
  #}
  }

