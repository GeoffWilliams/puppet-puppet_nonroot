# Puppet_nonroot
#
# Configure and start a non-root puppet agent (requires root agent already
# installed and running)
#
# @example Creating a non-root agent instance
#   puppet_nonroot { "puppet-azure-provisioner.megacorp.com":
#     user               => "azure-provisioner",
#     puppet_master_fqdn => "puppet.megacorp.com",
#   }
#
# @param puppet_master_fqdn Fully qualified domain name of the Puppet Master to
#   that will be managing this agent instance.  Must already be resolvable
# @param user Local user to run agent as (will be created)
# @param certname The unique identifier for this agent instance in Puppet
# @param homedir Set a custom homedir for `user`, otherwise default is `/home/$user`
# @param challenge_password Password for policy based autosigning
#   @see http://www.geoffwilliams.me.uk/puppet/policy_based_autosigning
# @param extension_requests Hash of extension requests
#   @see https://docs.puppet.com/puppet/4.10/ssl_attributes_extensions.html
define puppet_nonroot (
    String           $puppet_master_fqdn,
    String           $user,
    String           $certname           = $title,
    Optional[String] $homedir            = undef,
    Optional[String] $challenge_password = undef,
    Optional[Hash]   $extension_requests = {},
    Boolean          $manage_service     = true,
    Boolean          $service_enable     = true,
    String           $service_ensure     = 'running',
) {

  $_homedir       = pick($homedir, "/home/${user}")
  $puppet_home    = "${_homedir}/.puppetlabs/etc/puppet"
  $puppet_conf    = "${puppet_home}/puppet.conf"
  $csr_attributes = "${puppet_home}/csr_attributes.yaml"
  $service        = "puppet-${certname}"
  $unit           = "/etc/systemd/system/puppet-${certname}.service"

  # daemon reload - workaround for https://tickets.puppetlabs.com/browse/PUP-3483
  $nasty_systemd_hack = "${module_name}_systemd_hack"

  File {
    owner => $user,
    group => $user,
    mode  => "0640",
  }

  Ini_setting {
    ensure  => present,
    path    => $puppet_conf,
    section => 'agent',
  }

  user { $user:
    ensure => present,
    home   => $_homedir,
  }

  file { [
    $_homedir,
    "${_homedir}/.puppetlabs",
    "${_homedir}/.puppetlabs/etc/",
    "${_homedir}/.puppetlabs/etc/puppet"]:
    ensure => directory,
  }

  file { $puppet_conf:
    ensure => file,
  }

  if $challenge_password or ! empty($extension_requests) {
    file { $csr_attributes:
      ensure  => file,
      content => epp("${module_name}/csr_attributes.yaml.epp", {
        "challenge_password" => $challenge_password,
        "extension_requests" => $extension_requests,
      })
    }
  }

  ini_setting { "${puppet_conf} agent:certname":
    setting => 'certname',
    value   => $certname,
  }

  ini_setting { "${puppet_conf} agent:server":
    setting => 'server',
    value   => $puppet_master_fqdn,
  }

  if $manage_service {
    file { $unit:
      ensure  => file,
      notify  => Exec[$nasty_systemd_hack],
      content => epp("${module_name}/puppet.epp", {
        "user"     => $user,
        "certname" => $certname,
      }),
    }

    if ! defined(Exec[$nasty_systemd_hack]) {
      exec { $nasty_systemd_hack:
        command     => "systemctl daemon-reload",
        refreshonly => true,
        path        => ['/usr/sbin', '/sbin', '/usr/bin', '/bin'],
      }
    }

    service { $service:
      ensure  => $service_ensure,
      enable  => $service_enable,
      require => [File[$unit], Exec[$nasty_systemd_hack]],
    }
  }

}
