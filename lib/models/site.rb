class Site < ActiveRecord::Base
  has_many :articles, dependent: :destroy
  
  # Check if any new articles are posted
  # If so, add them to the database if they don't already exist
  # rubocop:disable Metrics/AbcSize
  def fetch_articles
    return unless any_new?
    (how_many? - 1).downto(0) do |index|
      next if added?(index)
      Article.create(title: feed.entries[index].title,
                     description: description(index),
                     published: feed.entries[index].published,
                     link: feed.entries[index].url,
                     site_id: id,
                     readingtime: reading_time(index))
    end
  end
  
  # Don't add articles with either:
  # 1. The same title; or
  # 2. A different title (title was changed) but same published date.
  # rubocop:disable Metrics/LineLength
  def added?(index)
    Article.where(title: feed.entries[index].title).exists? || Article.where(site_id: id, published: feed.entries[index].published).exists?
  end

  # Gets content of article
  # If content exists, get that first (full text)
  # If not, get summary (usually not full text)
  def description(index)
    feed.entries[index].content || feed.entries[index].summary
  end

  # Adds a reading time summary to each article
  def reading_time(index)
    words_per_second = 270 / 60
    total_words = description(index).scan(/\s+/).count
    article_time_seconds = total_words / words_per_second
    article_time_minutes = (article_time_seconds / 60).round

    return "less than a minute read" unless article_time_minutes > 0
    "#{article_time_minutes} min read"
  end

  private

  def feed
    @feed = Feedjira::Feed.fetch_and_parse feed_url
  end

  # Checks if there are any articles with a newer
  # published date than the last one in the
  # database
  def any_new?
    return true if articles.length == 0
    from_feed = feed.entries.first.published
    from_db = articles.last.published
    return true if from_feed > from_db
    false
  end

  # Returns Index + 1 of the new entries
  # in the feed, up to a maximum of 20
  def how_many?
    return default_article_sync if articles.length == 0
    last_db = articles.last.published
    count = 0
    feed.entries.each do |entry|
      count += 1 if entry.published > last_db
    end
    count > 20 ? 20 : count
  end

  # Sets default number of articles to sync
  # if the site has never synced before
  def default_article_sync
    feed.entries.count > 20 ? 20 : feed.entries.count
  end
end 
