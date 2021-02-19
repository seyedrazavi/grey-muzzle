require 'nokogiri'
require 'open-uri'

class NexusHtml

	NEXUS_DOMAIN = "phoenixbse.com"
	INDEX_PATH = "/index.php"
	HTML_BASE = "http://#{NEXUS_DOMAIN}#{INDEX_PATH}"

	def fetch_aff_profile(id)
		doc = doc("game", "affs",nil,id)
		begin
			aff_profile = parse_aff_profile(doc.xpath("//td[@class='phoenix_body']/table/tr[1]/td[1]/table"))
			aff_profile["relations"] = parse_aff_relations(doc.xpath("//div[@class='rel']"))
			#puts aff_profile
			return aff_profile
		rescue Exception => e
			puts "Error fetching profile for aff #{id} because #{e}"
			return {}
		end
	end

	private

	def parse_aff_profile(e_profile)
		aff_name = e_profile.xpath('.//tr[1]/td[1]/b[1]').first.content
		aff_code = e_profile.xpath('.//tr[2]/td[2]').first.content 
		#aff_description = e_profile.xpath('.//tr[3]/td[2]').first.content 
		#puts "#{aff_name} [#{aff_code}]"
		{
			"name_with_id" => aff_name,
			"code" => aff_code
		}
	end

	def parse_aff_relations(e_relations)
		#puts e_relations
		relations = {}
		e_relations.each do |e_rel|
			#puts e_rel['title']
			begin
				affs, relation = e_rel['title'].split(' : ')
				aff1, aff2 = affs.split('->')

				#puts "#{aff1} -> #{aff2} : #{relation}"

				relations[aff1] = {} unless relations[aff1]
				relations[aff1][aff2] = relation
			rescue Exception => e 
				puts "Could not parse relation #{e_rel['title']} because #{e}"
			end
		end
		relations
	end

	def doc(a, sa, ca=nil, id=nil)
		Nokogiri::HTML(URI.open(url(a, sa, ca, id)))
	end

	def url(a, sa=nil, ca=nil, id=nil)
		s = "#{HTML_BASE}?a=#{a}"
		s = "#{s}&sa=#{sa}" if sa 
		s = "#{s}&ca=#{ca}" if ca 
		s = "#{s}&id=#{id}" if id 
		s
	end
end

# nexus = NexusHtml.new
# nexus.fetch_aff_profile(67)