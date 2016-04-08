require 'yaml'
require 'erb'
require 'active_record'

template = ERB.new File.new("config/database.yml.erb").read
conf = YAML.load template.result(binding)
ActiveRecord::Base.establish_connection conf["development"]

require_relative '../lib/job_looper'
require_relative '../lib/models/site'
require_relative '../lib/models/article'
require_relative '../bin/fetch_articles_job'

articles_loop = JobLooper.new(Site, FetchArticlesJob, 900)

articles_loop.start_loop!