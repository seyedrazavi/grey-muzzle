require 'elasticsearch'
require 'elasticsearch/transport'
require 'dotenv/load'
require 'nokogiri'
require 'json'
require 'terminal-table'

LOGGING = false
ELASTICSEARCH_URL = ENV["ELASTICSEARCH_URL"]

SearchClient = Elasticsearch::Client.new(
  url: ELASTICSEARCH_URL,
  retry_on_failure: 5,
  request_timeout: 30,
  log: LOGGING,
)

def index_section(section_id, section)
	SearchClient.index(id: section_id, index: "rulebook", body: section)
end

def element_content_to_s(parent_element, element_name)
	path = ".//"+element_name
	parent_element.xpath(path).empty? ? nil : parent_element.xpath(path).first.content.strip
end

def element_content_to_i(parent_element, element_name)
	s = element_content_to_s(parent_element, element_name)
	s ? s.to_i : nil
end

def element_attribute_to_s(parent_element, element_name, attribute_name)
	path = ".//"+element_name
	parent_element.xpath(path).empty? ? nil : parent_element.xpath(path).first[attribute_name].strip
end

def element_attribute_to_i(element, name1, name2=nil)
	if name2.nil?
		return element ? (element[name1].nil? ? nil : element[name1].to_i) : nil
	else
		s = element_attribute_to_s(element, name1, name2)
		return s ? s.to_i : nil
	end
end

SECTION_ELEMENTS = ['sect1', 'sect2', 'sect3', 'sect4']

def parse_section_content(element)
	return unless element
	s = ""
	if element.name == 'orderedlist'
		print 'L'
		t = parse_ordered_list(element)
		s += t + "\n" if t
	elsif element.name == 'informaltable'
		print 'T'
		t = parse_informal_table(element)
		s += t + "\n" if t
	elsif element.name == 'para'
		print 'x'
		t = parse_para(element)
		s += t + "\n" if t
	end
	
	# element.children.each do |child_element|
	# 	if child_element.name == 'orderedlist'
	# 		print 'L'
	# 		t = parse_ordered_list(child_element)
	# 		s += t + "\n" if t
	# 	elsif child_element.name == 'informaltable'
	# 		print 'T'
	# 		t = parse_informal_table(child_element)
	# 		s += t + "\n" if t
	# 	elsif child_element.name == 'para'
	# 		print 'x'
	# 		t = parse_para(child_element)
	# 		s += t + "\n" if t
	# 	end
	# end
	
	s.strip!
	s = nil if s == ""
	s
end

def parse_para(element)
	return unless element
	begin
		s = element.content ? element.content.strip : nil 
		s = nil if s == ''
		s
	rescue Exception => e
		puts "Error parsing paragraph |#{element}| \nbecause #{e}"
		return nil 
	end
end

def parse_ordered_list(element)
	return unless element
	n = 1
	s = ""
	element.xpath('.//listitem').each do |e_item|
		s += "#{n}. #{element_content_to_s(e_item, 'para')}\n"
		n += 1
	end
	s
end

def parse_informal_table(element)
	return unless element
	table = Terminal::Table.new do |t|
		e_body = element.xpath('.//tbody').first
		if e_body
			e_body.xpath('.//row').each do |e_row|
				row = []
				e_row.xpath('.//entry').each do |e_entry|
					row << element_content_to_s(e_entry, 'para') || ""
				end
				t << row
			end
		end
	end
	"\n~```#{table}```~\n"
end

def parse_section(element, level=1, parent_id=nil)
	print '.'
	title = element_content_to_s(element, 'title')
	section_id = ""
	if parent_id
		section_id = "#{parent_id}//"
	end
	if title
		section_id = "#{section_id}#{title.downcase}"
	else
		section_id = "#{section_id}#{DateTime.now}"
	end
	section_id.strip!

	paras = []

	element.children.each do |child_element|
		s = parse_section_content(child_element)
		paras << s if s
	end

	section = {
		"title" => title,
		"paras" => paras,
		"parent_id" => parent_id,
		"level" => level
	}

	if paras.empty?
		puts "\n#{title} [#{section_id}] is empty [children: #{element.children.size}]"
	end
	#pp section
	response = index_section(section_id, section)
	section_id = response["_id"]
	next_level = level + 1
	if next_level < 4
		element.xpath(".//sect#{next_level}").each do |e_sub_section|
			parse_section(e_sub_section, next_level, section_id)
		end
	end
end

if SearchClient.indices.exists?(index: 'rulebook')
	SearchClient.indices.delete(index: 'rulebook')
	puts "Old index deleted"
end

index_settings = { number_of_shards: 1, number_of_replicas: 0 }
settings = { settings: { index: index_settings } }
SearchClient.indices.create(index: "rulebook", body: settings)

puts "Index created"

data = File.read 'rules.xml'
doc = Nokogiri::XML(data)

started = Time.now

doc.xpath('//sect1').each do |e_sect1|
	parse_section(e_sect1)
end

finished = Time.now

puts "\nFinished indexing rulebook (#{finished - started} seconds)"