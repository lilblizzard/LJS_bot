require 'nokogiri'
require 'open-uri'

@ljs_url = 'http://openn.library.upenn.edu/Data/0001/'
@ljs_html = Nokogiri::HTML(open(@ljs_url))

def random_manuscript_xml_url
  skip = ['Name', 'Last modified', 'Size', 'Parent Directory']
  hrefs = @ljs_html.css('div#div_directory a').reject { |node|
    skip.include? node.text
  }.map(&:text)
  random_manuscript = hrefs.sample.gsub('/', '')
  "#{@ljs_url}#{random_manuscript}/data/#{random_manuscript}_TEI.xml"
end

def manuscript_xml(xml_url)
  Nokogiri::XML(open(xml_url)).remove_namespaces!
end

def valid_xml?(xml)
  page_array = xml.xpath('//surface').select { |node|
    node['n'] =~ /^\d+[rv]/
  }.to_a
  page_array.length >= 4
end

def find_matching_images(manuscript_xml)
  page_array = manuscript_xml.xpath('//surface').to_a
  random_page = nil
  until random_page && random_page['n'] =~ /\d+v/
    random_page = page_array.sample
  end
  random_page_index = page_array.index(random_page)
  [page_array[random_page_index], page_array[random_page_index + 1]]
end

valid_xml = false
until valid_xml
  url = random_manuscript_xml_url
  xml = manuscript_xml(url)
  valid_xml = valid_xml?(xml)
end

puts url
puts find_matching_images(xml)




