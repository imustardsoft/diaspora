#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'rubygems'
require 'eventmachine'
config = YAML.load_file(File.dirname(__FILE__) + '/deploy_config.yml')

all = config['cross_server']

set :backers,  config['servers']['backer']
set :application, "diaspora"
set :deploy_to, all['deploy_to']
#set :runner, "diasporaroot"
#set :current_dir, ""
# Source code
set :scm, :git
set :user, all['user']
#set :user, ARGV[0]
set :password, all['password'] if all['password']
set :port, all['port']
set :scm_verbose, true
set :repository, all['repo']
set :branch, all['branch']
set :repository_cache, "remote_cache"
set :deploy_via, :checkout
#ssh_options[:forward_agent] = true
#set :ssh_options, { :forward_agent => true }
#
set :rails_env, ENV['rails_env'] || ENV['RAILS_ENV'] || all['default_env']

role :app, "64.147.122.43"
role :web, "64.147.122.43"
role :db,  "64.147.122.43", :primary => true
#role :tom,    "tom.joindiaspora.com"
#backers.each{ |backer|
#  role :backer, "#{backer['username']}.joindiaspora.com", :number => backer['number']
#}

#role :ci, "ci.joindiaspora.com"
# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

# Start Nginx
after "deploy:cold" do
  #run("nginx")
end

namespace :deploy do
  task :symlink_images do
    run "mkdir -p #{shared_path}/uploads"
    run "ln -s -f #{shared_path}/uploads #{current_path}/public/uploads"
  end

  task :symlink_bundle do
    run "mkdir -p #{shared_path}/bundle"
    run "ln -s -f #{shared_path}/bundle #{current_path}/vendor/bundle"
  end

  task :symlink_config do
    run "touch #{shared_path}/app_config.yml"
    run "ln -s -f #{shared_path}/app_config.yml #{current_path}/config/app_config.yml"
  end

  task :symlink_oauth_keys_config do
    run "touch #{shared_path}/oauth_keys.yml"
    run "ln -s -f #{shared_path}/oauth_keys.yml #{current_path}/config/oauth_keys.yml"
  end

  task :start do
      start_mongo
      start_thin
      start_websocket
  end
  
  task :start_websocket do
    run("cd #{current_path} && bundle exec ruby ./script/websocket_server.rb > /dev/null&")
  end

  task :start_mongo do
      run("mkdir -p -v #{current_path}/log/db/ ")
      run("mkdir -p -v #{shared_path}/db/")
      run("mongod  --fork --logpath #{current_path}/log/db/mongolog.txt --dbpath #{shared_path}/db/ " )

  end

  task :start_thin do
      run("mkdir -p -v #{current_path}/log/thin/ ")
      run("cd #{current_path} && bundle exec thin start -C config/thin.yml")
  end

  task :stop do
    stop_thin
    run("killall -s 2 mongod || true")
  end

  task :stop_thin do
    run("killall -s 2 ruby || true")
    #run("cd #{current_path} && bundle exec thin stop -C config/thin.yml || true")
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end

  task :bundle_gems do
    run "cd #{current_path} && bundle install"
  end

  task :reinstall_old_bundler do
    #run ("rm #{current_path}/Gemfile.lock || true")
    run 'gem list | cut -d" " -f1 | xargs gem uninstall -aIx || true '
    run "gem install bundler -v 0.9.26 || true"
  end

  task :update_bundler do
    run 'gem install bundler'
  end

  task :migrate do
  end
 end

namespace :cloud do
  task :reboot do
    run('reboot')
  end

  task :clear_bundle do

    run('cd && rm -r -f .bundle')
  end
end
namespace :db do

  task :purge, :roles => [:tom, :backer] do
    run "cd #{current_path} && bundle exec rake db:purge --trace RAILS_ENV=#{rails_env}"
  end

  task :tom_seed, :roles => :tom do
    run "cd #{current_path} && bundle exec rake db:seed:tom --trace RAILS_ENV=#{rails_env}"
  end

  task :backer_seed, :roles => :backer do
    run "cd #{current_path} && bundle exec rake db:seed:backer --trace RAILS_ENV=#{rails_env}"
  end

  task :reset do
    purge
    backer_seed
    tom_seed
  end
end

after "deploy:symlink", "deploy:symlink_images", "deploy:symlink_bundle", 'deploy:symlink_config', 'deploy:symlink_oauth_keys_config'
