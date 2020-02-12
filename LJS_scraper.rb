require 'nokogiri'
require 'open-uri'

# instance variable so that i can use them throughout
# the scope of the script
@ljs_url = 'http://openn.library.upenn.edu/Data/0001/'
@ljs_html = Nokogiri::HTML(open(@ljs_url))

def random_manuscript_xml_url
  skip = ['Name', 'Last modified', 'Size', 'Parent Directory']

  # take our page html and grab all <a> tags that are inside <div> tags
  # whose class is equal to div_directory. then, take all of those <a> tags
  # and reject any value that is equal to any word in our skip array. finally,
  # take the leftover tags and create an array of the text associated with
  # each tag.
  hrefs = @ljs_html.css('div#div_directory a').reject { |node|
    skip.include? node.text
  }.map(&:text)
  random_manuscript = hrefs.sample.gsub('/', '')
  "#{@ljs_url}#{random_manuscript}/data/#{random_manuscript}_TEI.xml"
end

def find_matching_images(xml_url)
  # removing namespaces so that we can xpath - lazy but works
  manuscript_xml = Nokogiri::XML(open(xml_url)).remove_namespaces!
  # create array of all Nokogiri nodes where the tag is <surface>
  # and the 'n' attribute starts with a number
  page_array = manuscript_xml.xpath('//surface').select {
      |node| node['n'][0] =~ /\d+/
  }.to_a
  # select first random page
  random_page = nil
  counter = 0
  until random_page && random_page['n'] =~ /\d+v/ # any digits followed by a v
    random_page = page_array.sample
    counter += 1
    break if counter > 1000 # to avoid infinite loop
  end
  random_page_index = page_array.index(random_page)
  [page_array[random_page_index], page_array[random_page_index + 1]]
end

url = random_manuscript_xml_url
puts url
puts find_matching_images(url)

