require "rubygems"
require "dotenv"
require "line/bot"
require "pry"
require "rest-client"
require 'google/apis/youtube_v3'
require "trollop"
require 'active_support'
require 'active_support/time'

DEVELOPER_KEY = ENV["YOUTUBE_API_KEY"]
# YOUTUBE_API_SERVICE_NAME = "youtube"
# YOUTUBE_API_VERSION = "v3"
#
# def get_service
#   client = Google::APIClient.new(
#     :key => DEVELOPER_KEY,
#     :authorization => nil
#   )
#   youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)
#
#   return client, youtube
# end
#
# def main
#   opts = Trollop::options do
#     opt :q, 'Search term', :type => String, :default => "筋肉"
#     opt :max_results, 'Max results', :type => :int, :default => 25
#   end
#
#   client, youtube = get_service
#
#   begin
#     # Call the search.list method to retrieve results matching the specified
#     # query term.
#     search_response = client.execute!(
#       :api_method => youtube.search.list,
#       :parameters => {
#         :part => 'snippet',
#         :q => opts[:q],
#         :maxResults => opts[:max_results]
#       }
#     )
#
#     videos = []
#     channels = []
#     playlists = []
#
#     # Add each result to the appropriate list, and then display the lists of
#     # matching videos, channels, and playlists.
#     search_response.data.items.each do |search_result|
#       case search_result.id.kind
#         when 'youtube#video'
#           videos << "#{search_result.snippet.title} (#{search_result.id.videoId})"
#         when 'youtube#channel'
#           channels << "#{search_result.snippet.title} (#{search_result.id.channelId})"
#         when 'youtube#playlist'
#           playlists << "#{search_result.snippet.title} (#{search_result.id.playlistId})"
#       end
#     end
#
#     puts "Videos:\n", videos, "\n"
#     puts "Channels:\n", channels, "\n"
#     puts "Playlists:\n", playlists, "\n"
#   rescue Google::APIClient::TransmissionError => e
#     puts e.result.body
#   end
# end
#
# main

def find_videos(keyword, after: 1.month.ago, before: Time.now)
  service = Google::Apis::YoutubeV3::YouTubeService.new
  service.key = DEVELOPER_KEY

  next_page_token = nil
  begin
    opt = {
      q: keyword,
      type: 'video',
      max_results: 50,
      order: :date,
      page_token: next_page_token,
      published_after: after.iso8601,
      published_before: before.iso8601
    }
    results = service.list_searches(:snippet, opt)
    results.items.each do |item|
      snippet = item.snippet
      puts "\"#{snippet.title}\" by #{snippet.channel_title} (#{snippet.published_at})"
    end

    next_page_token = results.next_page_token
  end while next_page_token.present?
end

find_videos('レノファ')
