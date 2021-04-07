require 'discordrb'
require 'json'
require 'dotenv/load'

require_relative 'cache'

# Bridge blaming

def set_bridge_blamed!
	dt = DateTime.now
	set_cache_value!('bridge_blamed', dt)
end

def bridge_blamed 
	get_cache_value('bridge_blamed')
end

def bridge_blamed_too_soon?
	last_blamed = bridge_blamed
	return false unless last_blamed
	last_blamed + 5 > DateTime.now
end

def blame_somebody!(event)
	unless event.content.downcase.include?("bridge") || bridge_blamed_too_soon?
		event << "I blame Bridge."
		set_bridge_blamed!
	end
end

