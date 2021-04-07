require 'discordrb'
require 'json'
require 'dotenv/load'

require_relative 'nexus_xml'
require_relative 'cache'
require_relative 'game_info'

# Game Status

def get_cached_status_datetime
	return nil unless get_cache_value('status_checked')
	DateTime.parse(get_cache_value('status_checked'))
end

def cache_status!(bot,post_to_channel=false)
	dt = DateTime.now
	old_status = get_cached_status
	client = NexusXml.new(ENV["XML_USER_ID"], ENV["XML_CODE"])
	status = client.fetch_status

	unless status
		return false
	end	

	set_cache_value!('status', status.to_json)
	set_cache_value!('status_checked', dt)

	puts "Cached status at #{dt}"
	
	if old_status && old_status["message"] != status["message"]
		puts "Status has changed"
		post_to_channel(bot, status["message"]) if bot && post_to_channel
		if status["day_finished"] && status["day_finished"] > 1
			puts "Day finished"
			cache_info!(bot)
		end
	end

	dt
end
