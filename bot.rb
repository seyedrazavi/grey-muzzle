require 'discordrb'
require 'json'
require 'dotenv/load'

require_relative 'nexus_xml'
require_relative 'rulebook'
require_relative 'helpers'
require_relative 'cache'
require_relative 'info_helpers'
require_relative 'game_status'
require_relative 'game_info'
require_relative 'blame'

ADMIN_USER = ENV['ADMIN_USER']

RATELIMIT_MESSAGE = "Discord forbids me to follow your command on this until %time%"
MAX_SEARCH_RESULTS = 3

MENTION_RESPONSES = ["I blame Bridge.", "My only vice is I like to slice it nice.", "Looks like the Felini are broke again.", "There's a Krell in my kitchen.", 
	"Skyth delenda est", "Imagine the horror of waking up as an Imperial.", "The Fat Fox says Greed is Good.", "Careful now. The DTR may put the kettle on.",
	"What is best in life? To crush your enemies, see them driven before you, and to hear the lamentation of their women.", "To be human is to err. To be Dewiek is to drink.",
	"Flatulance is the way of the Felini.", "I find your lack of faith disturbing.", "Do you want to play a game?", "Gordon is alive!", "Meklans on the starboard side!"]

bot = Discordrb::Commands::CommandBot.new token: ENV['GREYMUZZLE_TOKEN'], client_id: ENV['GREYMUZZLE_CLIENT_ID'], prefix: '!'

#
# Run on startup
#

cache_status!(bot)

if testing? 

	puts "--- TESTING ---"

	puts get_cached_status["message"]

	pp system_claim(1)

	pp item_description(400)

	pp market_buying_description(1)
	pp market_selling_description(1)

	pp market_starbase_description(301)

	chunk_message(system_claim(146)).each do |c|
		puts c 
	end

	pp affiliation_description(67)

	del_star_system!(1)

	star_system = get_star_system(1)
	if star_system
		star_system["claim"]["contested"] = "Yes"
		set_cache_value!(cache_id("star_systems",1), star_system.to_json)
	end

	aff = get_affiliation(67)
	aff["relations"]["DEN"]["ARC"] = "War"
	set_cache_value!(cache_id("affiliations",67), aff.to_json)

end

cache_info!(bot)

bot.heartbeat do |event|
	cache_status!(event.bot,true)
end

#
# Event handlers
#

bot.command(:status, min_args: 0, max_args: 0, description: 'Gets current game status', usage: '!status', rate_limit_message: RATELIMIT_MESSAGE) do |event|
	cache_status!(event.bot)
	event << get_cached_status["message"]
	react_to_command(event)
	
end

bot.command(:item, min_args: 1, max_args: 1, description: 'Gets item information', usage: '!item [Item ID]', rate_limit_message: RATELIMIT_MESSAGE) do |event, item_id|
	puts "!item: " + item_id
	cache_info!(bot) unless has_cached_info?
	send_user_pm(event.user, item_description(item_id))
	react_to_command(event)
end

bot.command(:claim, min_args: 1, max_args: 1, description: "Shows current system claim", usage: '!claim [System ID]', rate_limit_message: RATELIMIT_MESSAGE) do |event, system_id|
	puts "!claim: " + system_id
	cache_info!(bot) unless has_cached_info?
	send_user_pm(event.user, system_claim(system_id))
	react_to_command(event)
end

bot.command(:aff, min_args: 1, max_args: 1, description: "Shows current affiliation relations", usage: '!aff [Affiliation ID]', rate_limit_message: RATELIMIT_MESSAGE) do |event, aff_id|
	puts "!aff: " + aff_id
	cache_info!(bot) unless has_cached_info?
	send_user_pm(event.user, affiliation_description(aff_id))
	react_to_command(event)
end

bot.command(:buying, min_args: 1, max_args: 1, description: "Find out which markets are buying an item", usage: '!buying [Item ID]', rate_limit_message: RATELIMIT_MESSAGE) do |event, item_id|
	puts "!buying: " + item_id
	cache_info!(bot) unless has_cached_info?
	send_user_pm(event.user, "Currently unavilable") # market_buying_description(item_id))
	react_to_command(event)
end

bot.command(:selling, min_args: 1, max_args: 1, description: "Find out which markets are selling an item", usage: '!selling [Item ID]', rate_limit_message: RATELIMIT_MESSAGE) do |event, item_id|
	puts "!selling: " + item_id
	cache_info!(bot) unless has_cached_info?
	send_user_pm(event.user, "Currently unavilable") # market_selling_description(item_id))
	react_to_command(event)
end

bot.command(:market, min_args: 1, max_args: 1, description: "Get the public market for a starbase if it has one", usage: '!market [Starbase ID]', rate_limit_message: RATELIMIT_MESSAGE) do |event, starbase_id|
	puts "!market: " + starbase_id
	cache_info!(bot) unless has_cached_info?
	send_user_pm(event.user, "Currently unavilable") # market_starbase_description(starbase_id))
	react_to_command(event)
end

# bot.command(:rules, description: "Searches the BSE rulebook [experimental]", usage: "!rules [search terms]", rate_limit_message: RATELIMIT_MESSAGE) do |event, *query_parts|
# 	query = query_parts.join(' ')
# 	puts "!rules #{query}"
# 	results = Rulebook.search(query)
# 	react_to_command(event)
# 	if results.nil?
# 		send_user_pm(event.user, "Search not working.")
# 		post_to_channel(bot, "Search not working [null result].", CHANNEL_TEST_BOT)
# 	elsif results.count < 1
# 		send_user_pm(event.user, "Nothing found matching '#{query}' in the rulebook.")
# 	else
# 		max = results.count > MAX_SEARCH_RESULTS ? MAX_SEARCH_RESULTS : results.count
# 		send_user_pm(event.user, "Found #{results.count} matching sections in the rulebook. Will send the best #{max} results to you.")
# 		i = 0
# 		while i < max do 
# 			break unless results[i]
# 			send_user_pm(event.user, "#{results[i]}\n")
# 			sleep(1)
# 			i += 1
# 		end
# 	end
# end

bot.message(with_text: '!help') do |event|
	event << "Did you know you can PM me these commands?"
end

#
# Mentions
#

bot.mention do |event|
	event << MENTION_RESPONSES.sample
end

#
# Bridge tribute
#

bot.message(contains: ' blame') do |event|
	blame_somebody!(event)
end

bot.message(contains: ' wrong') do |event|
	blame_somebody!(event)
end

bot.message(contains: ' error') do |event|
	blame_somebody!(event)
end

bot.message(contains: ' broke') do |event|
	blame_somebody!(event)
end

bot.message(contains: ' fail') do |event|
	blame_somebody!(event)
end

bot.message(contains: ' fault') do |event|
	blame_somebody!(event)
end

bot.message(contains: ' crash') do |event|
	blame_somebody!(event)
end

bot.message(contains: ' GreyMuzzle') do |event|
	event << MENTION_RESPONSES.sample
end

bot.message(contains: ' bot ') do |event|
	event << MENTION_RESPONSES.sample
end

#
# Admin
#

bot.pm(from: ADMIN_USER) do |event|
	if event.content.start_with?("Say ")
		s = event.content[4,event.content.length-1]
		post_to_channel(event.bot, s)
		react_to_command(event)
	elsif event.content.strip.downcase == "refresh"
		cache_info!(bot)
		react_to_command(event)
	elsif !event.content.start_with?("!")
		event << "Yes, my master. [#{event.content}]"
		react_to_command(event)
	end
end

bot.run