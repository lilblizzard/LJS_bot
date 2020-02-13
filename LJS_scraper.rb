require 'nokogiri'
require 'open-uri'

# instance variable so that i can use them throughout
# the scope of the script
@ljs_url = 'http://openn.library.upenn.edu/Data/0001/'
@ljs_html = Nokogiri::HTML(open(@ljs_url))

def random_manuscript_xml_url
  skip = ['Name', 'Last modified', 'Size', 'Parent Directory']
  hrefs = @ljs_html.css('div#div_directory a').reject {
      |node| skip.include? node.text
  }.map(&:text)
  random_manuscript = hrefs.sample.gsub('/', '')
  "#{@ljs_url}#{random_manuscript}/data/#{random_manuscript}_TEI.xml"
end

# TODO - this function can sometimes return nil
# this screws over other functions that depend
# on its output to function properly
def xml_follows_naming_convention(xml_url)
  manuscript_xml = Nokogiri::XML(open(xml_url)).remove_namespaces!
  page_array = manuscript_xml.xpath('//surface').select {
      |node| node['n'] =~ /\d+/
  }.to_a
  if page_array.length >= 2
    manuscript_xml
  elsif page_array.nil?
    puts "#{xml_url} doesn't work."
  end
end

def find_matching_images(manuscript_xml)
  page_array = manuscript_xml.xpath('//surface').to_a
  random_page = nil
  counter = 0
  # TODO fix this loop from running infinitely
  until random_page && random_page['n'] =~ /\d+v/ || (counter == 100)
    random_page = page_array.sample
    counter += 1
    puts 'searching...'
  end
  random_page_index = page_array.index(random_page)
  [page_array[random_page_index], page_array[random_page_index + 1]]
end

# main loop
image_path_pair = nil
counter = 0
until image_path_pair || (counter == 1000)
  image_path_pair = find_matching_images(xml_follows_naming_convention(random_manuscript_xml_url))
  counter += 1
  puts image_path_pair
end




