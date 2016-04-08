require 'sidekiq'
require 'openssl'
require 'feedjira'
require 'yaml'
require 'active_record'

template = ERB.new File.new("config/database.yml.erb").read
conf = YAML.load template.result(binding)
ActiveRecord::Base.establish_connection conf["development"]

require_relative '../lib/models/site'
require_relative '../lib/models/article'

class FetchArticlesJob
  include Sidekiq::Worker
  
  def perform(site_id)
    # Don't worry about SSL Certificates when fetching feeds
    # Avoids OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=SSLv3
    # read server certificate B: certificate verify failed
    # Thank you to https://gist.github.com/siruguri/66926b42a0c70ef7119e
    OpenSSL::SSL.send(:remove_const, :VERIFY_PEER)
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    
    site = Site.find(site_id)
    site.fetch_articles
  end 
end 
