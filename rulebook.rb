require 'elasticsearch'
require 'elasticsearch/transport'
require 'dotenv/load'
require 'nokogiri'
require 'json'

LOGGING = false
ELASTICSEARCH_URL = ENV["ELASTICSEARCH_URL"] && ENV["ELASTICSEARCH_URL"] != "" ? ENV["ELASTICSEARCH_URL"] : nil

class Rulebook
	class Entry
		attr_accessor :title, :id, :body, :parent_id

		def initialize(id, title, body, parent_id=nil)
			self.id = id 
			self.title = title.strip 
			self.body = body
			self.parent_id = parent_id
		end

		def parent
			@parent ||= parent_id ? Rulebook.find_by_id(parent_id) : nil
		end

		def to_s
			s = ""
			if parent
				s = "*#{parent.title}*\n|- **#{self.title}**\n"
			else
				s = "**#{self.title}**\n"
			end
			s = s + "#{body}"
			# "**#{self.title}**\n#{body}"
		end
	end

	SearchClient = Elasticsearch::Client.new(
	  url: ELASTICSEARCH_URL,
	  retry_on_failure: 5,
	  request_timeout: 30,
	  log: LOGGING,
	)

	def self.search(q)
		self.query(q)
	end

	def self.find_by_id(id)
		results = self.query("_id:\"#{id}\"")
		results.count > 0 ? results[0] : nil
	end

	private
	def self.query(q)
		results = SearchClient.search(
		  index: "rulebook",
		  body: {
		    query: {
		      query_string: {
		        query: q,
		        analyze_wildcard: true,
		        allow_leading_wildcard: false
		      }
		    }
		  }
		)
		#puts "Took #{results["took"]}"
		hits = results["hits"]
		#puts "Total #{hits["total"]}"
		entries = []
		hits["hits"].each do |r|
			id = r["_id"]
			source = r["_source"]
			title = source["title"]
			parent_id = source["parent_id"]
			body = source["paras"].join("\n")
			e = Rulebook::Entry.new(id, title, body, parent_id)
			entries << e
		end
		entries
	end
end

# pp Rulebook.search("Armour")

#puts Rulebook.find_by_id("starships//scanning//scan+location")