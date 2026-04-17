class MetArtService
  SEARCH_URL = 'https://collectionapi.metmuseum.org/public/collection/v1/search'.freeze
  OBJECT_URL = 'https://collectionapi.metmuseum.org/public/collection/v1/objects'.freeze
  REDIS_KEY = 'met_art:current'.freeze

  def fetch_random_artwork
    object_ids = search_paintings
    return if object_ids.empty?

    # ランダムに選んで画像があるものを探す
    object_ids.sample(10).each do |id|
      data = fetch_object(id)
      next unless data && data['primaryImageSmall'].present?

      artwork = {
        image_url: data['primaryImage'],
        title: data['title'],
        artist: data['artistDisplayName'],
        date: data['objectDate']
      }

      Redis.new(url: ENV.fetch('REDIS_URL')).set(REDIS_KEY, artwork.to_json)
      return artwork
    end
  end

  def current_artwork
    json = Redis.new(url: ENV.fetch('REDIS_URL')).get(REDIS_KEY)
    return nil unless json

    JSON.parse(json, symbolize_names: true)
  end

  private

  def search_paintings
    response = HTTParty.get(
      SEARCH_URL,
      query: { hasImages: true, departmentId: 11, q: 'landscape painting' }
    )
    response.parsed_response['objectIDs'] || []
  end

  def fetch_object(id)
    response = HTTParty.get("#{OBJECT_URL}/#{id}")
    response.parsed_response
  end
end
