require 'discordrb'
require 'json'
require 'dotenv/load'

require_relative 'nexus_xml'
require_relative 'cache'

# Game Info

def get_cached_info(info_type, id)
	return nil unless get_cached_info_timestamp
	puts "Info Timestamp:" + get_cached_info_timestamp.to_s
	info = get_cache_value(cache_id(info_type, id))
	JSON.parse(info) if info
end

def del_cached_info!(info_type, id)
	return nil unless get_cached_info_timestamp
	del_cache_value!(cache_id(info_type, id))
end

def get_item(id)
	get_cached_info("items", id)
end

def get_star_system(id)
	get_cached_info("star_systems", id)
end

def get_affiliation(id) 
	get_cached_info("affiliations", id)
end

def get_item_type(id)
	get_cached_info("item_types", id)
end

def get_market_item(id)
	get_cached_info("market_items", id)
end

def get_market_starbase(id)
	get_cached_info("market_starbases", id)
end

def del_item!(id)
	del_cached_info!("items", id)
end

def del_star_system!(id)
	del_cached_info!("star_systems", id)
end

def del_affiliation!(id) 
	del_cached_info!("affiliations", id)
end

def del_item_type!(id)
	del_cached_info!("item_types", id)
end

def del_market_item!(id)
	del_cached_info!("market_items", id)
end

def del_market_starbase!(id)
	del_cached_info!("market_starbases", id)
end

def system_changed(bot, cache_id, old_value)
	puts "Star system #{cache_id} changed."

	begin
		old_system = JSON.parse(old_value) if old_value
		current_system = JSON.parse(get_cache_value(cache_id))

		aff_code = "#{current_system["claim"]["aff_code"]}"
		system_name = "#{current_system["name"]} (#{current_system["id"]})"

		if old_system.nil? || current_system["claim"]["contested"] != "No"
			message = "NEWS FLASH! New claim for #{system_name} system for #{aff_code}."
			post_to_channel(bot, message)
		end
	rescue Exception => e
		puts "Error handling system change for #{cache_id} because #{e}"
	end
end

def affiliation_changed(bot, cache_id, old_value) 
	puts "Affiliation #{cache_id} changed."

	begin
		old_affiliation = JSON.parse(old_value) if old_value
		current_affiliation = JSON.parse(get_cache_value(cache_id))

		aff_code = current_affiliation["code"]
		aff_name = current_affiliation["name_with_id"]

		old_relations = old_affiliation ? old_affiliation["relations"] : {}
		current_relations = current_affiliation["relations"]

		puts "!--- Old Relations --!"
		pp old_relations
		puts "!--- Current Relations --!"
		pp current_relations

		current_relations.keys.each do |aff1|
			current_relations[aff1].keys.each do |aff2|
				unless old_relations[aff1] && old_relations[aff1][aff2] == current_relations[aff1][aff2]
					message = "NEWS FLASH! #{aff1} is now #{current_relations[aff1][aff2]} wtih #{aff2}."
					post_to_channel(bot, message)
				end
			end
		end

		if old_relations
			old_relations.keys.each do |aff1|
				old_relations[aff1].keys.each do |aff2|
					unless current_relations[aff1][aff2] # existing relation so don't need to post again
						message = "NEWS FLASH! #{aff1} is now back to neutral relations wtih #{aff2}."
						post_to_channel(bot, message)
					end
				end
			end
		end

	rescue Exception => e
		puts "Error handling affiliation change for #{cache_id} because #{e}"
	end
end

def market_items_changed(bot, cache_id, old_value)
	puts "Market Items #{cache_id} changed."
end

def market_starbase_changed(bot, cache_id, old_value)
	puts "Market Starbase #{cache_id} changed."
end
