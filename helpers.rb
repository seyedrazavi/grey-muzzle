require 'discordrb'
require 'json'
require 'dotenv/load'

CHANNEL_DISCUSSIONS_OOC = 506015403148050442
CHANNEL_TEST_BOT = 810938988659474462

CHANNEL_ID = (ENV['TESTING'] == 'true') ? CHANNEL_TEST_BOT : CHANNEL_DISCUSSIONS_OOC

GREYMUZZLE_EMOJI = 811280919083089980

MAX_MESSAGE = 2000

# Helpers

def testing?
	ENV['TESTING'] == 'true'
end

def react_to_command(event)
	emoji = event.bot.emoji(GREYMUZZLE_EMOJI)
	event.message.react(emoji) 
end

def message_too_long?(message)
	message ? message.length > MAX_MESSAGE : false
end

def chunk_message(message)
	return unless message
	message = message.gsub("\n", "___").gsub("~```","\n```").gsub("```~","```\n")
	parts = message.scan(/.{1,2000}/)
	parts.map{|p| p.gsub("___", "\n")}
end

def post_to_channel(bot, message, channel_id=CHANNEL_ID)
	unless message_too_long?(message)
		bot.send_message(CHANNEL_ID, message)
	else
		chunks = chunk_message(message)
		chunks.each do |c|
			bot.send_message(CHANNEL_ID, c)
			sleep(1)
		end
	end
end

def send_user_pm(user, message)
	unless message_too_long?(message)
		user.pm message
	else
		chunks = chunk_message(message)
		chunks.each do |c|
			user.pm c
			sleep(1)
		end
	end
end

def reply_to_event(event, message)
	unless message_too_long?(message)
		event << message
	else
		chunks = chunk_message(message)
		chunks.each do |c|
			event << c
			sleep(1)
		end
	end
end
