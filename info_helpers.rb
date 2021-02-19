require 'discordrb'
require 'json'
require 'dotenv/load'

require_relative 'nexus_xml'

# Info helpers

def item_description(id)
	item = get_item(id)
	if item 
		description = "**" + item["name"] + " (#{id})**\n" + item["techmanual"] + "\n"
		NexusXml::ITEM_VALUE_FIELDS.each do |field_name|
			unless field_name == 'name' || item[field_name].nil? || item[field_name] == ''
				description += field_name.capitalize + ": " + item[field_name] + "\n"
			end
		end
		if item["rawmaterials"] && !item["rawmaterials"].empty?
			description += "Raw Materials:\n"
			item["rawmaterials"].values.each do |rm|
				description += "-\t #{rm["description"]}"
			end
		end
		return description
	else
		return "Item #{id} not found."
	end
end

def system_claim(id, detailed=true)
	sys = get_star_system(id)
	if sys 
		description = "**" + sys["name"] + " (#{id}) [#{sys["periphery"]}]**"
		if sys["claim"]
			claim = sys["claim"]
			description += " claimed for **#{claim["aff_code"]}** (#{claim["type"]})"
			if claim["contested"] != "No"
				description += " [Contested]"
			end
			if detailed
				description += ".\n"
				unless claim["aff_code"] == "ALL"
					claim["supporting"].each do |support|
						description += "-\t #{support["position"]} #{support["size"]}k for #{support["for"]}.\n"
					end
				end
			end
		else
			description += "unclaimed."
		end

		return description
	else
		return "System #{id} not found."
	end
end

def market_buying_description(id)
	market_item = get_market_item(id)
	if market_item
		description = "**Public markets buying " + market_item["name"] + " (#{id})**\n"
		if market_item["buying"].empty?
			description += "-\t Not being bought at any public market.\n"
		end

		market_item["buying"].each do |buy|
			starbase = buy["starbase"]
			starbase_location = if starbase["cbody"] && starbase["system"]
				"#{starbase["cbody"]}, #{starbase["system"]}"
			elsif starbase["system"]
				starbase["system"]
			end
			description += "-\t #{buy["quantity"]} @ $#{buy["price"]}\t\t #{starbase["aff"]} #{starbase["name"]} (#{starbase["id"]})\t #{starbase_location}\n"
		end

		return description
	else
		return "Item #{id} not found on markets."
	end
end

def market_selling_description(id)
	market_item = get_market_item(id)
	if market_item
		description = "**Public markets selling " + market_item["name"] + " (#{id})**\n"
		if market_item["selling"].empty?
			description += "-\t Not being sold at any public market.\n"
		end

		market_item["selling"].each do |sell|
			starbase = sell["starbase"]
			starbase_location = if starbase["cbody"] && starbase["system"]
				"#{starbase["cbody"]}, #{starbase["system"]}"
			elsif starbase["system"]
				starbase["system"]
			end

			description += "-\t #{sell["quantity"]} @ $#{sell["price"]}\t\t #{starbase["aff"]} #{starbase["name"]} (#{starbase["id"]})\t #{starbase_location}\n"
		end

		return description
	else
		return "Item #{id} not found on markets."
	end
end

def market_starbase_description(id)
	market_starbase = get_market_starbase(id)
	#pp market_starbase
	if market_starbase 
		description = "**" + market_starbase["name"] + " (#{id})**\n#{market_starbase["cbody"]}, #{market_starbase["system"]}\n"
		description += "Hiports: #{market_starbase["hiport"]}\n"
		description += "Orbital Docks: #{market_starbase["docks"] ? market_starbase["docks"] : 0} max hulls\n"

		unless market_starbase["selling"].nil? || market_starbase["selling"].empty?
			description += "\n*Selling*:\n"
			market_starbase["selling"].each do |sell|
				description += "-\t #{sell["item"]["name"]} (#{sell["item"]["id"]})\t\t #{sell["quantity"]} @ $#{sell["price"]}\n"
			end
		end

		unless market_starbase["buying"].nil? || market_starbase["buying"].empty?
			description += "\n*Buying*:\n"
			market_starbase["buying"].each do |buy|
				description += "-\t #{buy["item"]["name"]} (#{buy["item"]["id"]})\t\t #{buy["quantity"]} @ $#{buy["price"]}\n"
			end
		end

		return description
	else
		return "Starbase #{id} not found on markets."
	end
end

def affiliation_description(id)
	aff = get_affiliation(id)
	if aff 
		description = "**#{aff['name_with_id']}**\nRelations:\n"
		aff['relations'].keys.each do |aff1|
			aff['relations'][aff1].keys.each do |aff2|
				description += "-\t #{aff1} -> #{aff2} : #{aff['relations'][aff1][aff2]}\n"
			end
		end
		return description
	else
		return "Affiliation #{id} not found."
	end
end

