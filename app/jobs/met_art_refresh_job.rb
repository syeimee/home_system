class MetArtRefreshJob < ApplicationJob
  queue_as :default

  def perform
    MetArtService.new.fetch_random_artwork
  end
end
