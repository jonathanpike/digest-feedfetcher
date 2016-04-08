class Article < ActiveRecord::Base
  belongs_to :site

  validates :title, uniqueness: true
end