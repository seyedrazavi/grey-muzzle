require 'discordrb'
require 'json'
require 'dotenv/load'
require 'redis'

REDIS = Redis.new(url: ENV["REDIS_URL"], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })

def has_cached_info?
	!REDIS.get('info_fetched').nil?
end

def cache_id(info_type, id)
	"#{info_type}_#{id}"
end

def get_cache_value(id)
	REDIS.get(id)
end

def set_cache_value!(id, value)
	REDIS.set(id, value)
end

def del_cache_value!(id)
	REDIS.del(id)
end

def get_cached_status
	return nil unless get_cached_status_datetime
	puts "Status Timestamp:" + get_cached_status_datetime.to_s
	status = JSON.parse(REDIS.get('status'))
end

def get_cached_info_timestamp
	return nil unless get_cache_value('info_fetched')
	DateTime.parse(REDIS.get('info_fetched'))
end

def cache_info_set!(set_of_info, info_type)
	changed = []
	set_of_info.keys.each do |id|
		cache_id = cache_id(info_type, id)
		value = set_of_info[id].to_json
		old_value = get_cache_value(cache_id)
		if old_value.nil? || value != old_value
			changed << [cache_id, old_value] 
		end
		set_cache_value!(cache_id, value)
		#puts "SET #{prefix}_#{id}" + ":" + set_of_info[id].to_json
	end
	changed
end

def cache_info!(bot)
	dt = DateTime.now
	client = NexusXml.new(ENV["XML_USER_ID"], ENV["XML_CODE"])
	info = client.fetch_info
	unless info 
		return false
	end
	#pp info["items"]
	cache_info_set!(info["items"], "items")
	cache_info_set!(info["star_systems"], "star_systems").each do |cache_id, old_value|
		# system_changed(bot, cache_id, old_value)
	end
	cache_info_set!(info["affiliations"], "affiliations").each do |cache_id, old_value|
		# affiliation_changed(bot, cache_id, old_value)
	end
	cache_info_set!(info["item_types"], "item_types")
	set_cache_value!('info_fetched', dt)
	
	# market_starbases, market_items = client.fetch_market
	# cache_info_set!(market_items, "market_items")
	# cache_info_set!(market_starbases, "market_starbases")

	puts "Cached info at #{dt}"

	dt
end