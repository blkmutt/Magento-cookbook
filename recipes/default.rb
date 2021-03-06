include_recipe "apt"
include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "php"
include_recipe "apache2::mod_php5"
include_recipe "database::mysql"

%w{ php5-curl php5-gd php5-mcrypt php5-mysql }.each do |a_package|
  package a_package
end

mysql_connection_info = {:host => node['magento']['db_host'], :username => 'root', :password => node['mysql']['server_root_password']}

mysql_database node['magento']['db_name'] do
    connection mysql_connection_info
    encoding 'utf8'
    action :create
end

mysql_database_user node['magento']['db_user'] do
  connection mysql_connection_info
  password node['magento']['db_password']
  database_name node['magento']['db_name']
  action :grant
end

web_app "100-magento-site" do
  server_name node['fqdn']
  server_aliases [node['fqdn'], node['hostname']]
  docroot node['magento']['web_path']
end

execute "mage install" do
  user node['apache']['user']
  group node['apache']['group']
  cwd node['magento']['web_path']
  command "php -f install.php -- \
           \ --license_agreement_accepted 'yes' \
           \ --locale 'es_ES' \
           \ --timezone 'Europe/Madrid' \
           \ --default_currency 'EUR' \
           \ --db_host '#{node['magento']['db_host']}' \
           \ --db_name '#{node['magento']['db_name']}' \
           \ --db_user '#{node['magento']['db_user']}' \
           \ --db_pass '#{node['magento']['db_password']}' \
           \ --url 'http://#{node['fqdn']}' \
           \ --use_rewrites 'yes' \
           \ --skip_url_validation 'yes' \
           \ --use_secure 'no' \
           \ --secure_base_url '' \
           \ --use_secure_admin 'no' \
           \ --admin_firstname '#{node['magento']['admin_user']['firstname']}' \
           \ --admin_lastname '#{node['magento']['admin_user']['lastname']}' \
           \ --admin_email '#{node['magento']['admin_user']['email']}' \
           \ --admin_username '#{node['magento']['admin_user']['username']}' \
           \ --admin_password '#{node['magento']['admin_user']['password']}'"
  action :run
  creates "#{node['magento']['web_path']}/app/etc/local.xml"
end

execute "mage reindexall" do
  user node['apache']['user']
  group node['apache']['group']
  cwd node['magento']['web_path']
  command "php shell/indexer.php reindexall"
  action :run
end


