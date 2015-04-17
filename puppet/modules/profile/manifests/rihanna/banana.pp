class profile::rihanna::banana (
	$banana_host = localhost
) inherits profile::base {

	stage { "pre":
		before => Stage["riak"]
	}
	stage { "riak":
		before => Stage["riakbanana"]
	}
	stage { "riakbanana":
	}

  class { '::oracle_java':
		stage => pre
	}

  class { '::riak':
		stage => riak
  }

  class { '::riakbanana':
		banana_host => $banana_host,
		stage => riakbanana
	}

	class { '::logstash':
		manage_repo => true,
		repo_version => '1.4'
	}

	class { '::logstash_contrib':
		require => Package['logstash']
	}

	logstash::configfile { 'logstash-riak':
		content => template('profile/logstash-riak.erb'),
		notify => Service['logstash']
	}

}
