require 'yaml'
require 'active_record'

conf = YAML.load_file('config/database.yml')
ActiveRecord::Base.establish_connection conf["development"]

require_relative '../lib/job_looper'
require_relative '../lib/models/site'
require_relative '../lib/models/article'
require_relative '../bin/fetch_articles_job'

articles_loop = JobLooper.new(Site, FetchArticlesJob, 900)

articles_loop.start_loop!