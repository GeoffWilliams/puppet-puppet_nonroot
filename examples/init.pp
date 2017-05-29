#@PDQTest
puppet_nonroot { "puppetest1.demo.fake":
  user               => "puppet1",
  puppet_master_fqdn => "puppet.master.fake",
}
puppet_nonroot { "puppetest2.demo.fake":
  user               => "puppet2",
  puppet_master_fqdn => "puppet.master.fake",
}
