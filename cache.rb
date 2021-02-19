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