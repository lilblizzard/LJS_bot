require 'nokogiri'
require 'open-uri'
require 'down'
require 'dotenv/load'
require 'twitter'

LJS_URL = 'http://openn.library.upenn.edu/Data/0001/'.freeze

def random_manuscript(directory_html)
  skip = ['Name', 'Last modified', 'Size', 'Parent Directory']
  hrefs = directory_html.css('div#div_directory a').reject { |node|
    skip.include? node.text
  }.map(&:text)
  hrefs.sample.gsub('/', '')
end

def make_url(manuscript_id)
  "#{LJS_URL}#{manuscript_id}/data/#{manuscript_id}_TEI.xml"
end

def manuscript_xml(xml_url)
  Nokogiri::XML(open(xml_url)).remove_namespaces!
end

def manuscript_language(xml)
  xml.xpath('//textLang/text()')&.first&.text
end

def manuscript_title(xml)
  title = xml.xpath('//title').first.content
  title.slice!(/LJS.*$/)
end

def manuscript_summary(xml)
  summary = xml.xpath('//summary').first.content
  if summary.length > 260
    summary[0..260].gsub(/\s\w+\s*$/, '...')
  else
    summary.slice!(/^([^.]+)/)
  end
end

def valid_xml?(xml)
  page_array = xml.xpath('//surface').select { |node|
    node['n'] =~ /^\d+[rv]/
  }.to_a
  page_array.length >= 4
end

def find_matching_nodes(manuscript_xml)
  page_array = manuscript_xml.xpath('//surface').to_a
  random_page = nil
  until random_page && random_page['n'] =~ /\d+v/
    random_page = page_array.sample
  end
  random_page_index = page_array.index(random_page)
  [page_array[random_page_index], page_array[random_page_index + 1]]
end

def get_urls_from_nokogiri_nodes(nodes, manuscript)
  first_url = '/' + nodes[0].children[5].attributes['url']
  second_url = '/' + nodes[1].children[5].attributes['url']
  [LJS_URL + manuscript + '/data' + first_url,
   LJS_URL + manuscript + '/data' + second_url]
end

def download_image(url, dest)
  open(url) do |u|
    File.open(dest, 'wb') { |f| f.write(u.read) }
  end
end

valid_xml = false
until valid_xml
  manuscript = random_manuscript(Nokogiri::HTML(open(LJS_URL)))
  url = make_url(manuscript)
  xml = manuscript_xml(url)
  valid_xml = valid_xml?(xml)
end

matching_nodes = find_matching_nodes(xml)
url_array = get_urls_from_nokogiri_nodes(matching_nodes, manuscript)
if manuscript_language(xml) =~ /arabic|hebrew|persian|ottoman turkish|yiddish/i
  url_array.reverse!
  puts 'switched'
else
  url_array
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV['API_KEY']
  config.consumer_secret = ENV['API_SECRET_KEY']
  config.access_token = ENV['ACCESS_TOKEN']
  config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
end

url_array.each_with_index { |url, index|
  download_image(url, 'images/page_' + index.to_s + '.jpg')
}
media = %w[/app/images/page_0.jpg
           /app/images/page_1.jpg].map { |filename|
  File.new filename
}

main_tweet = client.update_with_media(manuscript_title(xml), media)
summary_tweet = client.update(manuscript_summary(xml),
                              in_reply_to_status_id: main_tweet.id)
link_tweet = client.update('Interested in this manuscript? Learn more here! ' +
                               LJS_URL + 'html/' +
                               @random_manuscript + '.html',
                           in_reply_to_status_id: summary_tweet.id)

puts url
puts manuscript_language(xml)
puts url_array
