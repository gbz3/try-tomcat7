%w{ java-1.7.0-openjdk java-1.7.0-openjdk-devel }.each do |pkg|
  package pkg do
    action :install
  end
end

t7dir = "apache-tomcat-7.0.42"
jmxjar = "catalina-jmx-remote.jar"

bash "download tomcat7" do
  user 'root'
  group 'root'
  cwd '/tmp'
  code <<-EOC
    curl -o "#{t7dir}.tar.gz" "http://ftp.meisei-u.ac.jp/mirror/apache/dist/tomcat/tomcat-7/v7.0.42/bin/apache-tomcat-7.0.42.tar.gz"
  EOC
  creates "/tmp/#{t7dir}.tar.gz"
end

bash "download jmx" do
  user 'root'
  group 'root'
  cwd '/tmp'
  code <<-EOC
    curl -o "#{jmxjar}" "http://ftp.meisei-u.ac.jp/mirror/apache/dist/tomcat/tomcat-7/v7.0.42/bin/extras/#{jmxjar}"
  EOC
  creates "/tmp/#{jmxjar}"
end

bash "install tomcat7" do
  user 'root'
  group 'root'
  cwd '/usr/local'
  code <<-EOC
    tar zx --exclude='*webapps/*' --exclude='*temp/*' -f "/tmp/#{t7dir}.tar.gz"
    test -h /usr/local/tomcat && rm -f /usr/local/tomcat
    ln -s "#{t7dir}" tomcat
    cp "/tmp/#{jmxjar}" /usr/local/tomcat/lib
  EOC
  creates "/usr/local/tomcat/lib/#{jmxjar}"
end

dmdir = "commons-daemon-1.0.15-native-src"

bash "daemonize tomcat7" do
  user 'root'
  group 'root'
  cwd '/usr/local/tomcat/bin'
  environment(
    "JAVA_HOME" => '/usr/lib/jvm/java',
    "CATALINA_HOME" => '/usr/local/tomcat'
  )
  code <<-EOC
    test -d "#{dmdir}" && rm -rf "#{dmdir}"
    tar zxf commons-daemon-native.tar.gz && cd "#{dmdir}/unix" && ./configure && make && cp jsvc ../..
  EOC
  creates "/usr/local/tomcat/bin/jsvc"
end

user "tomcat" do
end

bash "post-install tomcat7" do
  user 'root'
  group 'root'
  cwd '/usr/local/tomcat'
  code <<-EOC
    chown -RL tomcat:tomcat /usr/local/tomcat
  EOC
end

template "/usr/local/tomcat/bin/setenv.sh" do
  source "setenv.sh.erb"
  owner "root"
  group "root"
  mode  "0755"
end

template "/etc/init.d/tomcat7" do
  source "tomcat7.erb"
  owner "root"
  group "root"
  mode  "0755"
end

service "tomcat7" do
  action [ :enable, :start ]
end

