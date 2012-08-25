default[:bind9][:secret] = "NeTXYjf3EAdZwewvHlID5H4kdFHhg6yci87inTdrPrD6pz9E2ajVUlv2GrOHbGrzeiLBQeIMpjb/3RB90bTVFA=="

case platform
when "centos","redhat","fedora","scientific","amazon"
  default[:bind9][:config_file] = "/etc/named.conf"
  default[:bind9][:data_path] = "/var/named"
  default[:bind9][:dump_file] = "cache_dump.db"
  default[:bind9][:user] = "named"
else
  default[:bind9][:config_path] = "/etc/bind"
  default[:bind9][:data_path] = "/var/cache/bind"
  default[:bind9][:dump_file] = "bind_dump.db"
  default[:bind9][:user] = "bind"
end

