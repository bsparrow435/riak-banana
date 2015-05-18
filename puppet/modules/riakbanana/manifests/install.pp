class riakbanana::install inherits riakbanana {

# logstash's riak output doesn't currently understand bucket types, so we'll
#    install them directly via bucket properties

### Banana

  package { 'git':
    ensure => installed
  } ->
  exec { 'install banana':
    command => "git clone https://github.com/LucidWorks/banana.git",
    cwd => "${banana_install_dir}",
    creates => "${banana_install_dir}/banana",
  } ->
  file { 'console dashboard':
    path => "${banana_install_dir}/banana/src/app/dashboards/default.json",
    content => template("riakbanana/console_dashboard.json.erb"),
    ensure => present
  }
  file { 'stats dashboard':
    path => "${banana_install_dir}/banana/src/app/dashboards/stats.json",
    content => template("riakbanana/stats_dashboard.json.erb"),
    ensure => present
  }
### Nginx

  package { 'nginx':
    ensure => installed
  } ->
  file { 'nginx config':
    path => "/etc/nginx/sites-available/default",
    content => template("riakbanana/nginx.conf.erb"),
    ensure => present
  } ~>
  service { 'nginx':
    ensure => running,
  }

### Riak console log Solr Schema & Bucket

  file { 'console schema file':
    path => "/tmp/console_schema.xml",
    content => template("riakbanana/console_schema.xml.erb"),
    ensure => present
  } ->
  exec { 'install console schema':
    command => "curl -XPUT '${riak_url}/search/schema/${console_index}' -H 'content-type: application/xml' --data-binary @/tmp/console_schema.xml",
    unless => "curl '${riak_url}/search/schema/${console_index}' -f > /dev/null 2>&1",
  } ->
  exec { 'install console index':
    command => "curl -XPUT '${riak_url}/search/index/${console_index}' -H 'content-type: application/json' -d '{\"schema\":\"${console_index}\"}'",
    unless => "curl -s '${riak_url}/search/index/${console_index}' -f > /dev/null 2>&1",
  } ->
  exec { 'wait_for_index console':
    command => "curl -f '${riak_url}/search/index/${console_index}' > /dev/null 2>&1",
    tries => 20,
    try_sleep => 5,
  } ->
  exec { 'configure console bucket':
    command => "curl -H 'content-type: application/json' -XPUT '${riak_url}/buckets/${console_index}/props' -d '{\"props\":{\"search_index\":\"${console_index}\"}}'",
    unless => "curl -s '${riak_url}/buckets/${console_index}/props' | grep '\"search_index\":\"${console_index}\"' > /dev/null 2>&1",
    require => Exec['install console index']
  }

### Riak stats log Solr Schema and Bucket

  file { 'stats schema file':
    path => "/tmp/stats_schema.xml",
    content => template("riakbanana/stats_schema.xml.erb"),
    ensure => present
  } ->
  exec { 'install stats schema':
    command => "curl -XPUT '${riak_url}/search/schema/${stats_index}' -H 'content-type: application/xml' --data-binary @/tmp/stats_schema.xml",
    unless => "curl '${riak_url}/search/schema/${stats_index}' -f > /dev/null 2>&1",
  } ->
  exec { 'install stats index':
    command => "curl -XPUT '${riak_url}/search/index/${stats_index}' -H 'content-type: application/json' -d '{\"schema\":\"${stats_index}\"}'",
    unless => "curl -s '${riak_url}/search/index/${stats_index}' -f > /dev/null 2>&1",
  } ->
  exec { 'wait_for_index stats':
    command => "curl -f '${riak_url}/search/index/${stats_index}' > /dev/null 2>&1",
    tries => 20,
    try_sleep => 5,
  } ->
  exec { 'configure stats bucket':
    command => "curl -H 'content-type: application/json' -XPUT '${riak_url}/buckets/${stats_index}/props' -d '{\"props\":{\"search_index\":\"${stats_index}\"}}'",
    unless => "curl -s '${riak_url}/buckets/${stats_index}/props' | grep '\"search_index\":\"${stats_index}\"' > /dev/null 2>&1",
    require => Exec['install stats index']
  }

}
