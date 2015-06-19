# Parse DSD SDMX, for SDMX format 2.0 
# --------------------------------------------------------------------------------
# Arguments:
# FILE - DSD file (xml)
# OUTPUT_FORMAT - use SQLITE
# example:
# ruby parse_dsd.rb NA_SEC+ESTAT+v2_0+1.5.xml SQLITE
###################################################################################################
require_relative "lib/helper_xml"
require 'htmlentities'
coder = HTMLEntities.new
require 'formatador'
###################################################################################################
#arguments
file = nil
output_format = nil
ARGV.each_with_index do |a, i|  
  if i+1 == 1 then
	file = a	
  elsif i+1 == 2 then
	output_format = a		
  end
end 
if file.nil? then abort("Enter the name of DSD SDMX file!") end
if output_format.nil? then abort("Enter target format: SQLITE") end
###################################################################################################
#variables
v_comment = "--"
v_ddl_header = ''
v_ddl_footer = ''
v_ddl_prefix = '' 
v_ddl_prefix2 = ''
v_ddl_sufix = ''
v_ddl_sufix0 = '' 	
v_break_line = "----------------------------------------------------------------------------------"
###################################################################################################
#start
Formatador.display('[green]')
system "cls"
puts v_break_line
puts "DSD Parser started at #{Time.now.to_s}."
puts "DSD file = #{file}"
puts "Export format = #{output_format}"
puts v_break_line
Formatador.display('[/]')
#open file for DDL
export_file = File.open("result/"+file+"_"+output_format+"_ddl", "w")
export_file.puts v_ddl_header
export_file.puts v_comment + v_break_line
export_file.puts v_comment + "DSD Parser started at #{Time.now.to_s}."
export_file.puts v_comment + "DSD file = #{file}"
export_file.puts v_comment + "Export format = #{output_format}"
export_file.puts v_comment + v_break_line

############################################################################################
# CodeLists
puts "\n" + 'CodeLists ... '					
export_file.puts "\n" + v_comment + 'CodeLists'
v_elementi_col = ''
v_elementi_val = ''
v_table = "CodeLists"
v_counter = 1
arr_cl = [] 
arr_codes = [] 

# CREATE and INSERT statements for CodeLists table
v_statement_create = "CREATE TABLE " + v_table + " ("
v_statement_insert = "INSERT INTO " + v_table + " ("

Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do
	for_element 'str:CodeList' do
		v_statement_insert = "INSERT INTO " + v_table + " ("
		v_statement_create2 = "CREATE TABLE "
		tmp = @node.attributes
		inside_element do
					for_element 'str:Name' do	
						tmp = tmp.merge @node.attributes 
						#merge the element
						tmp = tmp.merge Hash[name.sub('str:',''), inner_xml]
						
						if v_counter == 1 then
							v_statement_create = "CREATE TABLE " + v_table + " (" + tmp.map{|f| f[0] }.join(" char, ")	+ ' char);'
							#puts v_statement_create															
							export_file.puts v_ddl_prefix + v_statement_create +  v_ddl_sufix0 + "\n" + v_ddl_sufix										
							v_counter = v_counter + 1
						end						
						v_statement_insert = v_statement_insert + tmp.map{|f| f[0] }.join(", ") + ") VALUES (" + "'"+tmp.map{|f| coder.encode(f[1], :basic)+"'" }.join(", '")+");"		
												
						arr_cl.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]							
					end	
					
					for_element 'str:Code' do						
						tmp2 = @node.attributes.merge Hash['CodeList', tmp["id"]] 
						inside_element do
							for_element 'str:Description' do
								tmp2 = tmp2.merge @node.attributes 
								tmp2 = tmp2.merge Hash[name.sub('str:',''), inner_xml]								
								arr_codes.push Hash[tmp2.map{|sym| [sym[0], sym[1].to_s]}]
							end
						end					
					end
					
		end	
		#puts v_statement_insert	
		export_file.puts v_ddl_prefix + v_statement_insert +  v_ddl_sufix0 + "\n" + v_ddl_sufix
				
	end
end
puts 'OK'

############################################################################################
#create tables & inserts - from CodeLists 
v_counter = 0
last_cl = ''
v_statement_insert2 = "INSERT INTO "

arr_codes.each do |code|	
	v_statement_insert2 = "INSERT INTO "
	#puts code	 
	v_statement_insert2 = v_statement_insert2 + code["CodeList"] + " (" 
	if code["CodeList"] != last_cl then 
		v_counter = 1 
		last_cl = code["CodeList"]
	end
	code = code.delete_if {|key, value| key == "CodeList" } 
	
	#fix - "rename" value to code
	code["code"] = code["value"]
	code = code.delete_if {|key, value| key == "value" }
		
	#puts code
	if v_counter == 1 then
		v_statement_create2 = "CREATE TABLE " 
		v_statement_create2 = v_statement_create2 + last_cl + " (" + code.map{|f| f[0] }.join(" char, ") + ' char);'
		
		#puts v_statement_create2
		export_file.puts v_ddl_prefix + v_statement_create2 +  v_ddl_sufix0 + "\n" + v_ddl_sufix
		
		# for each code list create UNIQUE index on column code
		export_file.puts v_ddl_prefix + 'CREATE UNIQUE INDEX IND_'+last_cl+' ON '+last_cl+' (code);' + v_ddl_sufix0 + "\n" + v_ddl_sufix			
		v_counter = 0
	end
	v_statement_insert2 = v_statement_insert2 + code.map{|f| f[0] }.join(", ") + ") VALUES (" + "'"+code.map{|f| coder.encode(f[1], :basic) +"'" }.join(", '")+");"	
	export_file.puts v_ddl_prefix + v_statement_insert2 +  v_ddl_sufix0 + "\n" + v_ddl_sufix
end
puts 'Create UNIQUE index on "code" for each codelist table ...'
puts 'OK'


############################################################################################
# Concepts
puts "\n" + 'Concepts ... '					
export_file.puts "\n" + v_comment + 'Concepts'
v_elementi_col = ''
v_elementi_val = ''
v_counter = 1
v_table = "Concepts"
arr_concepts = [] 

#CREATE and INSERT statement for table Concepts
Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do    		
	for_element 'str:Concept' do
		v_statement_insert = "INSERT INTO " + v_table + " ("
		tmp = @node.attributes			
		#puts name			
		inside_element do
			for_element 'str:Name' do	
				tmp = tmp.merge @node.attributes 				
								
				#merge an element - in this case str:Name						
				tmp = tmp.merge Hash[name.sub('str:',''), inner_xml]
				
				if v_counter == 1 then
					v_statement_create = "CREATE TABLE " + v_table + " (" + tmp.map{|f| f[0] }.join(" char(60), ")	+ ' char(60));'
					#puts v_statement_create															
					export_file.puts v_ddl_prefix + v_statement_create +  v_ddl_sufix0 + "\n" + v_ddl_sufix										
					v_counter = v_counter + 1
				end				
				v_statement_insert = v_statement_insert + tmp.map{|f| f[0] }.join(", ") + ") VALUES (" + "'"+tmp.map{|f| f[1]+"'" }.join(", '")+");"
								
				arr_concepts.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]								
			end
		end						
		#puts v_statement_insert		
		export_file.puts v_ddl_prefix + v_statement_insert +  v_ddl_sufix0 + "\n" + v_ddl_sufix		
	end				
 end
 puts 'OK'
# Concepts - end


############################################################################################
# KeyFamilies
puts "\n" + 'KeyFamilies ... '					
export_file.puts "\n" + v_comment + 'KeyFamilies'
v_elementi_col = ''
v_elementi_val = ''
v_table = "KeyFamilies"

#CREATE and INSERT statement for table KeyFamilies
v_statement_create = "CREATE TABLE " + v_table + " ("
v_statement_insert = "INSERT INTO " + v_table + " ("
Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do
    for_element 'str:KeyFamily' do		
		inside_element  do	
			for_element 'str:Name' do				
				v_elementi_col = v_elementi_col + ", " + name + " char"
				v_elementi_val = v_elementi_val + ", '" + inner_xml + "'"				
			end
			for_element 'str:Description' do								
				v_elementi_col = v_elementi_col + ", " + name + " char"
				v_elementi_val = v_elementi_val + ", '" + inner_xml + "'"				
			end
		end

		#atributtes
		#default to char (for now)
		v_statement_create = v_statement_create + @node.attributes.map{|f| f[0] }.join(" char(20), ") + " char(20)"+  v_elementi_col +");"
		v_statement_insert = v_statement_insert + @node.attributes.map{|f| f[0] }.join(", ") + v_elementi_col.gsub!(' char', '') + ") VALUES ('" + @node.attributes.map{|f| f[1] }.join("', '") + "'" + v_elementi_val + ");"
		
		#fix
		v_statement_create = v_statement_create.gsub! 'str:', ''
		v_statement_insert = v_statement_insert.gsub! 'str:', ''
		
		#puts v_statement_create						
		#puts v_statement_insert					
		export_file.puts v_ddl_prefix + v_statement_create +  v_ddl_sufix0 + "\n" + v_ddl_sufix
		export_file.puts v_ddl_prefix + v_statement_insert +  v_ddl_sufix0 + "\n" + v_ddl_sufix	
		
	end		
 end
 puts 'OK'
# KeyFamilies - end


############################################################################################
#Dimensions
puts "\n" + 'Dimensions ... '					
export_file.puts "\n" + v_comment + 'Dimensions'
v_elementi_col = ''
v_elementi_val = ''
v_counter = 1
v_table = "Dimensions"
arr_dim = []

#CREATE and INSERT statement for table Dimensions
Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do    		
	for_element 'str:Dimension' do
		v_statement_insert = "INSERT INTO " + v_table + " ("
		tmp = @node.attributes									
		inside_element do
			for_element 'str:TextFormat' do	
				tmp = tmp.merge @node.attributes 				
				
				if v_counter == 1 then
					v_statement_create = "CREATE TABLE " + v_table + " (" + tmp.map{|f| f[0] }.join(" char(20), ")	+ ' char(20));'
					#puts v_statement_create															
					export_file.puts v_ddl_prefix + v_statement_create +  v_ddl_sufix0 + "\n" + v_ddl_sufix										
					v_counter = v_counter + 1
				end				
				v_statement_insert = v_statement_insert + tmp.map{|f| f[0] }.join(", ") + ") VALUES (" + "'"+tmp.map{|f| f[1]+"'" }.join(", '")+");"
								
				arr_dim.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]								
			end
		end									
		
		export_file.puts v_ddl_prefix + v_statement_insert +  v_ddl_sufix0 + "\n" + v_ddl_sufix		
	end				
 end
 puts 'OK'
# Dimensions - end

############################################################################################
#TimeDimension
puts "\n" + 'TimeDimension ... '					
export_file.puts "\n" + v_comment + 'TimeDimension'
v_elementi_col = ''
v_elementi_val = ''
v_counter = 1
v_table = "TimeDimension"
arr_timedim = [] 

#CREATE and INSERT statement for table TimeDimension
Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do    		
	for_element 'str:TimeDimension' do
		v_statement_insert = "INSERT INTO " + v_table + " ("
		tmp = @node.attributes			
		#puts name			
		inside_element do
			for_element 'str:TextFormat' do	
				tmp = tmp.merge @node.attributes 							
				
				if v_counter == 1 then
					v_statement_create = "CREATE TABLE " + v_table + " (" + tmp.map{|f| f[0] }.join(" char, ")	+ ' char);'
					#puts v_statement_create															
					export_file.puts v_ddl_prefix + v_statement_create +  v_ddl_sufix0 + "\n" + v_ddl_sufix										
					v_counter = v_counter + 1
				end				
				v_statement_insert = v_statement_insert + tmp.map{|f| f[0] }.join(", ") + ") VALUES (" + "'"+tmp.map{|f| f[1]+"'" }.join(", '")+");"
								
				arr_timedim.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]								
			end
		end						
		#puts v_statement_insert		
		export_file.puts v_ddl_prefix + v_statement_insert +  v_ddl_sufix0 + "\n" + v_ddl_sufix		
	end				
 end
 puts 'OK'
# TimeDimension - end

############################################################################################
#Attributes
puts "\n" + 'Attributes ... '					
export_file.puts "\n" + v_comment + 'Attributes'
v_elementi_col = ''
v_elementi_val = ''
v_counter = 1
v_table = "Attributes"
arr_attr = [] 

#CREATE and INSERT statement for table Attributes
Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do    		
	for_element 'str:Attribute' do
		v_statement_insert = "INSERT INTO " + v_table + " ("
		tmp = @node.attributes			
						
		inside_element do
			for_element 'str:TextFormat' do	
				tmp = tmp.merge @node.attributes 					
				
				if v_counter == 1 then
					#fix - attribute isTimeFormat					
					#v_statement_create = "CREATE TABLE " + v_table + " (" + tmp.map{|f| f[0] }.join(" char(20), ")	+ ' char(20));'
					v_statement_create = "CREATE TABLE " + v_table + " (" + tmp.map{|f| f[0] }.join(" char(20), ")	+ ' char(20), isTimeFormat char(20));'
					#puts v_statement_create															
					export_file.puts v_ddl_prefix + v_statement_create +  v_ddl_sufix0 + "\n" + v_ddl_sufix										
					v_counter = v_counter + 1
				end				
				v_statement_insert = v_statement_insert + tmp.map{|f| f[0] }.join(", ") + ") VALUES (" + "'"+tmp.map{|f| f[1]+"'" }.join(", '")+");"
								
				arr_attr.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]								
			end
		end								
		#puts v_statement_insert		
		export_file.puts v_ddl_prefix + v_statement_insert +  v_ddl_sufix0 + "\n" + v_ddl_sufix		
	end				
 end
 puts 'OK'
# Attributes - end

############################################################################################
#PrimaryMeasure
puts "\n" + 'PrimaryMeasure ... '					
export_file.puts "\n" + v_comment + 'PrimaryMeasure'
v_elementi_col = ''
v_elementi_val = ''
v_counter = 1
v_table = "PrimaryMeasure"
arr_primmeas = [] 

#CREATE and INSERT statement for table PrimaryMeasure
Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do    		
	for_element 'str:PrimaryMeasure' do
		v_statement_insert = "INSERT INTO " + v_table + " ("
		tmp = @node.attributes			
					
		inside_element do
			for_element 'str:TextFormat' do	
				tmp = tmp.merge @node.attributes 							
				
				if v_counter == 1 then
					v_statement_create = "CREATE TABLE " + v_table + " (" + tmp.map{|f| f[0] }.join(" char, ")	+ ' char);'
					#puts v_statement_create															
					export_file.puts v_ddl_prefix + v_statement_create +  v_ddl_sufix0 + "\n" + v_ddl_sufix										
					v_counter = v_counter + 1
				end				
				v_statement_insert = v_statement_insert + tmp.map{|f| f[0] }.join(", ") + ") VALUES (" + "'"+tmp.map{|f| f[1]+"'" }.join(", '")+");"
								
				arr_primmeas.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]								
			end
		end	
				
		export_file.puts v_ddl_prefix + v_statement_insert +  v_ddl_sufix0 + "\n" + v_ddl_sufix		
	end				
 end
 puts 'OK'
# PrimaryMeasure - end

############################################################################################
# Create Fact table 
# F_OBSERVATIONS

puts "\n" + 'Fact Table (Observations) ... '					
export_file.puts "\n" + v_comment + 'Fact Table (Observations)'
v_table = 'F_OBSERVATIONS'

arr_fact = []
arr_concepts.each do |concept|			
	#puts concept
	is_column = 0
	v_dim = arr_dim.select{|key, hash| key["conceptRef"] == concept["id"] }
	v_attr = arr_attr.select{|key, hash| key["conceptRef"] == concept["id"]  }
	v_primmeas = arr_primmeas.select{|key, hash| key["conceptRef"] == concept["id"]  }
	v_timedim = arr_timedim.select{|key, hash| key["conceptRef"] == concept["id"]  }
			
	if !v_dim.empty? then
		v_dim = v_dim[0]
		v_row = Hash['column', concept["id"]]
		v_row = v_row.merge Hash['type', 'Dimension']
		v_row = v_row.merge Hash['column_type', v_dim["textType"]]
		v_row = v_row.merge Hash['max_length', v_dim["maxLength"]]
		v_row = v_row.merge Hash['min_length', v_dim["minLength"]]
		v_row = v_row.merge Hash['assignment_status', 'Mandatory']  # dimensions = always mandatory 
		v_row = v_row.merge Hash['fk_table', v_dim["codelist"]]     # constraint FK - code list table
		is_column = 1
	end
	
	if !v_attr.empty? then 
		v_attr = v_attr[0]
		v_row = Hash['column', concept["id"]]
		v_row = v_row.merge Hash['type', 'Attribute']
		v_row = v_row.merge Hash['column_type', v_attr["textType"]]
		v_row = v_row.merge Hash['max_length', v_attr["maxLength"]]
		v_row = v_row.merge Hash['min_length', v_attr["minLength"]]
		v_row = v_row.merge Hash['assignment_status', v_attr["assignmentStatus"]]  
		v_row = v_row.merge Hash['fk_table', v_attr["codelist"]]     			   # constraint FK - code list table
		is_column = 1
	end
	
	if !v_primmeas.empty? then 
		v_primmeas = v_primmeas[0]
		v_row = Hash['column', concept["id"]]
		v_row = v_row.merge Hash['type', 'PrimaryMeasure']
		v_row = v_row.merge Hash['column_type', v_primmeas["textType"]]
		v_row = v_row.merge Hash['max_length', v_primmeas["maxLength"]]
		v_row = v_row.merge Hash['assignment_status', 'Mandatory']       # primary measure = always mandatory
		v_row = v_row.merge Hash['fk_table', v_primmeas["codelist"]]     # constraint FK - code list table
		is_column = 1
	end
	
	if !v_timedim.empty? then 
		v_timedim = v_timedim[0]
		v_row = Hash['column', concept["id"]]
		v_row = v_row.merge Hash['type', 'TimeDimension']
		v_row = v_row.merge Hash['column_type', v_timedim["textType"]]
		v_row = v_row.merge Hash['assignment_status', 'Mandatory']       # time dimension = always mandatory
		v_row = v_row.merge Hash['fk_table', v_timedim["codelist"]]      # constraint FK - code list table		
		is_column = 1
	end
	
	# add to list only if it should become columnin fact table
	if is_column == 1	
		arr_fact.push v_row	
	end	
end

#puts arr_fact
v_statement_create = "CREATE TABLE " + v_table + " (" + arr_fact.map{|f| f["column"]+" "+f["column_type"].to_s+"("+f["max_length"].to_s+")" }.join(", ")	+ ');'

#SDMX_2-1_SECTION_6_TechnicalNotes.pdf
#Observational Time Period: Superset of all SDMX time formats (Gregorian Time Period, Reporting Time Period, and Time Range) 
#fix (for now) ObservationalTimePeriod -> String
v_statement_create = v_statement_create.sub('ObservationalTimePeriod()', 'String(40)')
#fix (for now) for COLL_PERIOD 
v_statement_create = v_statement_create.sub('ObservationalTimePeriod', 'String')
#fix REF_YEAR_PRICE - error in dsd <str:Attribute>, missing textType="String"
v_statement_create = v_statement_create.sub('REF_YEAR_PRICE (', 'REF_YEAR_PRICE String(')

export_file.puts v_ddl_prefix + 'CREATE TABLE '+v_table + ' ('
export_file.puts v_ddl_prefix + 'COMPOSITE_KEY String(255)'
arr_fact.each_with_index do |f, ind|
	tmp_row = ''
	# _REF_YEAR_PRICE misses type, length = 4
	# _TIME_PERIOD ObservationalTimePeriod()
	# _COLL_PERIOD ObservationalTimePeriod(35)
	tmp_row = f["column_type"].to_s + '(' + f["max_length"].to_s + ')'
	#fixes
	if f["column"] == 'REF_YEAR_PRICE' then tmp_row = 'String(4)' end
	if f["column"] == 'TIME_PERIOD' then tmp_row = 'String(35)' end
	if f["column"] == 'COLL_PERIOD' then tmp_row = 'String(35)' end
	if f["assignment_status"] == 'Mandatory' then tmp_row = tmp_row + ' NOT NULL' end
		
	val = ','
	export_file.puts val + '_' +f["column"]+'_ID '+tmp_row		
end	
puts 'OK'
puts 'Create CONSTRAINT - for Mandatory and Conditional columns in fact table (in CREATE statement) ...'
puts 'OK'

#FK constraints
arr_fact.each_with_index do |f, ind2|		
	if !f["fk_table"].nil?	
	#puts f					
		export_file.puts ', FOREIGN KEY (_'+f["column"]+'_ID) REFERENCES '+f["fk_table"]+'(code)'
	end
end
export_file.puts ');'
	
puts 'Create FK (in CREATE statement) ...'		
puts 'OK'	

puts "\n" + 'Stage Table (Observations Stage) ... '					
export_file.puts "\n" + v_comment + 'Stage Table (Observations Stage)'
export_file.puts 'CREATE TABLE '+v_table + '_STAGE AS SELECT * from '+v_table + ';'
puts 'Create STAGE table ...'		
puts 'OK'	

puts "\n" + 'History Table (Observations History) ... '					
export_file.puts "\n" + v_comment + 'History Table (Observations History)'
export_file.puts 'CREATE TABLE '+v_table + '_H AS SELECT cast(null as number) S_VERSION, cast(null as number) S_USER, cast(null as number) S_DATE, o.* from '+v_table + ' o;'
puts 'Create History table ...'		
puts 'OK'

puts "\n" + 'Index on composite_key ... '					
export_file.puts "\n" + v_comment + 'Index on composite_key ...'
export_file.puts 'CREATE INDEX ind_comp_key ON '+v_table+' ( COMPOSITE_KEY );'	
puts 'OK'

export_file.puts "\n"

# end
puts "\n" + v_break_line
puts "DSD Parser finished at #{Time.now.to_s}."
puts "Created file name: result/#{file+"_"+output_format+"_ddl"}"
puts v_break_line
export_file.puts "\n" + v_comment + v_break_line
export_file.puts v_comment + "DSD Parser finished at #{Time.now.to_s}."
export_file.puts v_comment + "Created file name: #{file+"_"+output_format+"_ddl"}"
export_file.puts v_comment + v_break_line
export_file.puts v_ddl_footer
export_file.close