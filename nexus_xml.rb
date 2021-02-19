require 'nokogiri'
require 'open-uri'

require_relative 'nexus_html'

class NexusXml
	attr_reader :user_id, :xml_code, :html_client

	ALPHA = 1
	BETA = 2
	GAMMA = 3
	DELTA = 4

	QUADS = [ALPHA, BETA, GAMMA, DELTA]

	QUAD_NAMES = {'Alpha' => 1, 'Beta' => 2, 'Gamma' => 3, 'Delta' => 4}
  	QUAD_NUMBERS = {1 => 'Alpha', 2 => 'Beta', 3 => 'Gamma', 4 => 'Delta'}

	MIN_RING = 1
	MAX_RING = 15

	NEXUS_DOMAIN = "phoenixbse.com"
	INDEX_PATH = "/index.php"
	XML_BASE = "http://#{NEXUS_DOMAIN}#{INDEX_PATH}"
	MARKET_XML = "#{XML_BASE}?a=game&sa=markets&type=xml"

	ITEM_VALUE_FIELDS = ['name', 'type', 'mus', 'prod', 'output', 'rawoutput', 'race', 'subtype', 'lifeform', 'subitem', 'subratio', 'tech', 'noprodsub', 'infratype', 'infraenvtype', 'infravalue', 'inframax', 'moverate0', 'itype']

	PERIPHERY_NAMES = {
		3 => "Cluster",
		9 => "Heartland",
		14 => "Coreward Arm",
		2 => "Darkfold",
		4 => "Dewiek Home",
		5 => "Dewiek Pocket",
		6 => "Detinus Republic",
		10 => "Flagritz Empire",
		11 => "Felini Empire",
		13 => "Halo",
		1 => "Inner Capellan",
		8 => "Inner Empire",
		0 => "None",
		16 => "Orion Spur",
		12 => "Outer Capellan",
		17 => "Perfidion Reach",
		15 => "Transpiral",
		7 => "Twilight"
	}

	def initialize(user_id,xml_code)
		@user_id = user_id
		@xml_code = xml_code
		@html_client = NexusHtml.new
	end

	def fetch_status
		puts "Fetching game status..."
		begin
			doc = doc('game_status')
			parse_status(doc.xpath('//game_status'))
		rescue Exception => e 
			puts "Failed to fetch game status because #{e}"
			return nil
		end
	end

	def fetch_info
		puts "Fetching info data..."

		begin
			doc = doc('info_data')
			parse_info(doc.xpath('//data_types'))
		rescue Exception => e 
			puts "Failed to fetch info because #{e}"
			return nil
		end
	end

	def fetch_items
		puts "Fetching item data..."

		begin
			doc = doc('items')
			parse_items(doc.xpath('//items'))
		rescue Exception => e 
			puts "Failed to fetch items because #{e}"
			return nil
		end
	end

	def fetch_systems
		puts "Fetching systems data..."

		begin
			doc = doc('systems')
			parse_systems(doc.xpath('//systems'))
		rescue Exception => e 
			puts "Failed to fetch systems because #{e}"
			return nil
		end
	end

	def fetch_market
		puts "Fetching market data..."

		begin
			doc = market_doc
			parse_market_starbases(doc.xpath('//starbase'))
		rescue Exception => e 
			puts "Failed to fetch market data because #{e}"
			return nil
		end
	end

	private
	def convert_timestamp(t)
		t > 1 ? Time.at(t) : nil
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

	def status_step(status, field_name, completed_label, active_label)
		s = ""
		if status[field_name]
			if status[field_name] > 1
				s = s + " | #{completed_label}: #{convert_timestamp(status[field_name]).strftime("%H:%M")}"
			elsif status[field_name] == 1
				s = s + " | #{active_label}"
			end
		end
		s
	end

	def status_string(status)
		s = "Star Date: #{status["star_date"]}"
		s += status_step(status, "turns_downloaded", "Downloaded", "Downloading")
		s += status_step(status, "turns_processed", "Processed", "Processing")
		s += status_step(status, "turns_uploaded", "Uploaded", "Uploading")
		s += status_step(status, "emails_sent", "Emails", "Emailing")
		s += status_step(status, "specials_processed", "Specials", "Specials Processing")
		s += status_step(status, "day_finished", "Finished", "Finishing")
		s
	end

	def parse_status(e_status)
		status = {
			"status" => element_content_to_s(e_status, 'status'),
			"current_day" => element_content_to_s(e_status, 'current_day'),
			"year_start" => element_content_to_s(e_status, 'year_start'),
			"turns_downloaded" => element_content_to_i(e_status, 'turns_downloaded'),
			"turns_processed" => element_content_to_i(e_status, 'turns_processed'),
			"turns_uploaded" => element_content_to_i(e_status, 'turns_uploaded'),
			"emails_sent" => element_content_to_i(e_status, 'emails_sent'),
			"specials_processed" => element_content_to_i(e_status, 'specials_processed'),
			"day_finished" => element_content_to_i(e_status, 'day_finished'),
			"star_date" => element_content_to_s(e_status, 'star_date')
		}
		status["message"] = status_string(status)
		
		status
	end

	def parse_items(e_data_type)
		items = {}
		e_data_type.xpath('.//data').each do |e_data|
			id = element_attribute_to_i(e_data,'num')
			i = {"id" => id, "name" => e_data['name']}
			items[id] = i
		end
		items
	end

	def parse_star_systems(e_data_type)
		systems = {}
		e_data_type.xpath('.//data').each do |e_data|
			id = element_attribute_to_i(e_data, 'num')
			s = {"id" => id, "name" => e_data['name']}
			systems[id] = s
		end
		systems
	end

	def parse_affiliations(e_data_type)
		affiliations = {}
		e_data_type.xpath('.//data').each do |e_data|
			id = element_attribute_to_i(e_data, 'num')
			a = {"id" => id, "name" => e_data['name']}
			profile_options = html_client.fetch_aff_profile(id)
			a = a.merge(profile_options)
			#pp a
			affiliations[id] = a
		end
		affiliations
	end
	
	def parse_item_types(e_data_type)
		item_types = {}
		e_data_type.xpath('.//data').each do |e_data|
			id = element_attribute_to_i(e_data, 'num')
			t = {"id" => id, "name" => e_data['name']}
			item_types[id] = t
		end
		item_types
	end

	def parse_info(e_data_types)
		info = {}

		e_data_types.xpath('.//type').each do |e_data_type|
			if e_data_type['name'] == 'Items'
				puts "Fetched known items"
				info["items"] = fetch_items # parse_items(e_data_type)
			elsif e_data_type['name'] == 'Systems'
				puts "Fetched known star systems"
				info["star_systems"] = fetch_systems # parse_star_systems(e_data_type)
			elsif e_data_type['name'] == 'Affiliation'
				puts "Fetched known affilitions"
				info["affiliations"] = parse_affiliations(e_data_type)
			elsif e_data_type['name'] == 'Item Type'
				puts "Fetched known item types"
				info["item_types"] = parse_item_types(e_data_type)
			end
		end

		info
	end

	def parse_items(e_items)
		items = {}

		e_items.xpath('.//items').each do |e_item|
			id = element_attribute_to_i(e_item, 'key')
			#pp e_item if id == "1"
			item = {"id" => id}
			ITEM_VALUE_FIELDS.each do |field_name|
				item[field_name] = element_attribute_to_s(e_item, field_name, 'value')
			end
			item["techmanual"] = element_content_to_s(e_item, 'techmanual')
			unless e_item.xpath('.//rawmaterials').empty? 
				item["rawmaterials"] = {}
				 e_item.xpath('.//rawmaterials').xpath('.//rawmaterials').each do |e_raw_material|
				 	e_rm_item = e_raw_material.xpath('.//item').first
				 	e_rm_quantity = e_raw_material.xpath('.//quantity').first
				 	unless e_rm_item.nil?
					 	rm_id = element_attribute_to_i(e_rm_item, 'value') 
					 	quantity = element_attribute_to_i(e_rm_quantity, 'value')
					 	rm = {"id" => rm_id, "quantity" =>  quantity}
						item["rawmaterials"][rm_id] = rm
					end
				 end
			end
			items[id] = item
		end

		items.values.each do |item|
			if item['subitem'] 
				subitem_id = item['subitem']
				subitem = items[subitem_id]
				if subitem
					item['subitem'] = subitem["name"] + " (#{subitem_id})"
				end
			end
			if item["rawmaterials"]
				item["rawmaterials"].keys.each do |rm_id|
					rm = item["rawmaterials"][rm_id]
					quantity = rm["quantity"]
					#pp rm
					#puts " [" + quantity + "]" unless quantity.nil?
					rm_item = items[rm_id]
					if rm_item
						rm["description"] = "#{rm_item["name"]} (#{rm_id}) x #{rm["quantity"]}\n"
					else
						rm["description"] = "(#{rm_id}) x #{rm["quantity"]}\n"
					end
				end
			end
		end

		items
	end

	def parse_systems(e_systems)
		systems = {}

		e_systems.xpath('.//system').each do |e_system|
			id = e_system["id"]
			sys = {"id" => id, "name" => e_system['name'], "periphery" => PERIPHERY_NAMES[element_attribute_to_i(e_system, "periphery_id")]}
			cbodies = []
			e_system.xpath('.//cbody').each do |e_cbody|
				cbody = {
					"name" => e_cbody['name'],
					"id" => e_cbody['id'],
					"quad" => e_cbody['quad'],
					'ring' => e_cbody['ring']
				}
				cbodies << cbody
			end
			sys["cbodies"] = cbodies

			links = []
			e_system.xpath('.//link').each do |e_link|
				link = {
					"sys_id" => e_link['sys_id'],
					"dist" => e_link['dist'],
					"name" => e_link['name']
				}
				links << link
			end
			sys["links"] = links

			unless e_system.xpath('.//system_claim').empty?
				e_system_clam = e_system.xpath('.//system_claim').first
				claim = {
					"aff_code" => e_system_clam['aff_code'],
					"aff_id" => e_system_clam['aff_id'],
					"contested" => e_system_clam['contested'],
					"type" => e_system_clam['type']
				}

				unless claim["aff_code"] == "ALL"
					supporting = []
					e_system_clam.xpath('.//support').xpath('.//claim').each do |e_support|
						support = {
							"for" => e_support['for'],
							"size" => e_support['size'],
							"position" => e_support['position']
						}
						supporting << support
					end
					claim['supporting'] = supporting
				end

				sys["claim"] = claim
			else
				sys["claim"] = nil
			end

			systems[id] = sys
		end

		systems
	end

	def parse_market_starbases(e_starbases)
		starbases = {}
		items = {}
		e_starbases.each do |e_starbase| 
			starbase_id = element_attribute_to_i(e_starbase,'id')
			starbase = {
				"id" => starbase_id,
				"aff" => element_content_to_s(e_starbase, 'aff'),
				"name" => element_content_to_s(e_starbase, 'name'),
				"hiport" => element_attribute_to_i(e_starbase, 'hiport', 'quant'),
				"docks" => element_attribute_to_i(e_starbase, 'docks', 'quant')
			}
			# pp starbase
			if element_content_to_s(e_starbase, 'system')
				starbase["system"] = "#{element_content_to_s(e_starbase, 'system')} (#{element_attribute_to_s(e_starbase, 'system', 'id')})"
			end
			if element_content_to_s(e_starbase, 'cbody')
				starbase["cbody"] = "#{element_content_to_s(e_starbase, 'cbody')} (#{element_attribute_to_s(e_starbase, 'cbody', 'id')})"
			end
				
			e_starbase.xpath('.//item').each do |e_item|
				item_id = element_attribute_to_i(e_item, "id")
				item = {
					"id" => item_id,
					"name" => element_content_to_s(e_item,'name')
				}
				buy = nil
				sell = nil
				if e_item.xpath('.//buy').first
					buy = {
						"quantity" => element_attribute_to_i(e_item, 'buy', 'quant'),
						"price" => element_attribute_to_s(e_item, 'buy', 'price')
					}
				end

				if e_item.xpath('.//sell').first
					sell = {
						"quantity" => element_attribute_to_i(e_item, 'sell', 'quant'),
						"price" => element_attribute_to_s(e_item, 'sell', 'price')
					}
				end

				unless items[item_id]
					items[item_id] = item.clone
					items[item_id]["buying"] = []
					items[item_id]["selling"] = []
				end

				unless buy.nil?
					starbase_buy = buy.clone
					starbase_buy["item"] = item
					buy["starbase"] = starbase.clone
					items[item_id]["buying"] << buy

					starbase["buying"] = [] unless starbase["buying"]
					starbase["buying"] << starbase_buy 
				end

				unless sell.nil?
					starbase_sell = sell.clone
					starbase_sell["item"] = item
					sell["starbase"] = starbase.clone
					items[item_id]["selling"] << sell

					starbase["selling"] = [] unless starbase["selling"]
					starbase["selling"] << starbase_sell
				end

				starbases[starbase_id] = starbase
			end
		end
		return starbases, items
	end

	def market_doc
		Nokogiri::HTML(URI.open("#{XML_BASE}?a=game&sa=markets&type=xml"))
	end

	def doc(data_type)
		Nokogiri::HTML(URI.open(url(data_type)))
	end

	def url(data_type)
		"#{XML_BASE}?a=xml&uid=#{@user_id}&code=#{@xml_code}&sa=#{data_type}"
	end
end