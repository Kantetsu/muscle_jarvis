require 'dotenv'
require 'sinatra'
require 'line/bot'
require "pry"
require 'rest-client'

module Line
  module Bot
    class HTTPClient
      def post(url, payload, header = {})
        RestClient.proxy = ENV["FIXIE_URL"]
        RestClient.post(url, payload, header)
      end
    end
  end
end

def client
  Dotenv.load
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        message = {
          type: 'text',
          text: event.message['text']
        }
        case message[:text]
        when "メニュー"
          messages = menu_select
        when "youtuber"
          messages = youtuber_list
        else
          messages = research_youtube(message[:text])
        end
        client.reply_message(event['replyToken'], messages)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end

private

def youtube_api(word)
  res = RestClient.get(URI.encode "https://www.googleapis.com/youtube/v3/search?key=#{ENV["YOUTUBE_API_KEY"]}&part=snippet&q=#{word}")
  result = JSON.parse(res.body)
  youtube_movies = []
  result["items"].each_with_index do |item, index|
    youtube_movie = {title: item["snippet"]["title"], url: "https://www.youtube.com/watch?v=#{item["id"]["videoId"]}"}
    youtube_movies.push(youtube_movie)
  end
  return youtube_movies
end

# メニューを表示させる
def menu_select
  messages = []
  first_message = {
    type: "text",
    text: "どこを鍛えたいですか？"
  }
  messages.push(first_message)
  second_message = {
    "type": "template",
    "altText": "this is a buttons template",
    "template": {
      "type": "buttons",
      "title": "どこの部位を鍛えたいですか？",
      "text": "以下の部位から選択してください",
      "actions": [
        {
          "type": "message",
          "label": "上腕二頭筋",
          "text": "上腕二頭筋"
        },
        {
          "type": "message",
          "label": "上腕三頭筋",
          "text": "上腕三頭筋"
        },
        {
          "type": "message",
          "label": "大胸筋",
          "text": "大胸筋"
        },
        {
          "type": "message",
          "label": "腹筋",
          "text": "腹筋"
        }
      ]
    }
  }
  messages.push(second_message)
  return messages
end

# youtuberのリストを表示
def youtuber_list
  messages = []
  first_message = {
    type: "text",
    text: "筋トレ動画をよくあげているYoutuberです"
  }
  messages.push(first_message)
  second_message = {
    "type": "template",
    "altText": "this is a carousel template",
    "template": {
      "type": "carousel",
      "columns": [
        {
          "title": "サイヤマングレート",
          "text": "腹筋ローラーといえばこの人です。",
          "thumbnailImageUrl": "https://www.dropbox.com/s/hf3hl1on28xnq33/image02.jpg?dl=1",
          "actions": [
            {
              "type": "uri",
              "label": "Youtubeチャンネル",
              "uri": "https://www.youtube.com/channel/UCCJel9mmTsxDU9RiCwdiLiA"
            },
            {
              "type": "message",
              "label": "サイヤマングレート",
              "text": "サイヤマングレート"
            }
          ]
        },
        {
          "title": "ボディーコーディネーターyoshi",
          "text": "ほかのyoutubeチャンネルとは違い、動画のクオリティが高く、解説などもしっかりしています。",
          "thumbnailImageUrl": "https://www.dropbox.com/s/cn31outsdcv0yan/image03.jpg?dl=1",
          "actions": [
            {
              "type": "uri",
              "label": "Youtubeチャンネル",
              "uri": "https://www.youtube.com/user/mensdiet"
            },
            {
              "type": "message",
              "label": "ボディーコーディネーターyoshi",
              "text": "ボディーコーディネーターyoshi"
            }
          ]
        },
        {
          "title": "kotochan33",
          "text": "初心者から上級者まで幅広くカバーした筋トレ方法や、知識を丁寧な口調で説明してくれます。",
          "thumbnailImageUrl": "https://www.dropbox.com/s/belbz05t35cegwb/image01.jpg?dl=1",
          "actions": [
            {
              "type": "uri",
              "label": "Youtubeチャンネル",
              "uri": "https://www.youtube.com/user/katochan33"
            },
            {
              "type": "message",
              "label": "kotochan33",
              "text": "kotochan33"
            }
          ]
        }
      ]
    }
  }
  messages.push(second_message)
  return messages
end

# 動画を検索
def research_youtube(message)
  messages = []
  first_message = {
    type: "text",
    text: "おすすめの動画が見つかりました"
  }
  messages.push(first_message)
  youtube_api(message).each_with_index do |youtube, index|
    reply = {
      type: "text",
      text: "#{youtube[:title] + " " + youtube[:url]}"
    }
    messages.push(reply)
    break if index == 3
  end
  return messages
end
