# --------------------------------------------------------------------------------
# Args
# SERIES_FILE - name of file with DDL (series)
# FORMAT      - SQLLITE
# KEY_FAMILY  - name of field with DSD (xml)
#
# ruby parse_sdmx_series.rb example_sdmx_data.xml SQLITE NA_SEC+ESTAT+v2_0+1.5.xml
# --------------------------------------------------------------------------------

###################################################################################################
require_relative "lib/helper_xml"
require 'htmlentities'
coder = HTMLEntities.new
###################################################################################################
file = nil
output_format = nil
key_family = nil
ARGV.each_with_index do |a, i|  
  if i+1 == 1 then
	file = a	
  elsif i+1 == 2 then
	output_format = a		
  elsif i+1 == 3 then
	key_family = a  
  end
end 
if file.nil? then abort("Enter the name of SDMX file with series data!") end
if output_format.nil? then abort("Enter the format: SQLLITE (for now only that value is allowed)!") end
if key_family.nil? then abort("Enter the name of DSD file (example. NA_SEC+ESTAT+v2_0+1.5.xml") end

###################################################################################################
#vars
v_comment = "--"
v_dml_header = ''
v_dml_footer = ''
v_dml_prefix = '' 
v_dml_sufix = ''
v_dml_sufix0 = '' 	
v_break_line = "----------------------------------------------------------------------------------"

#start
system "cls"
puts v_break_line
puts "Series Loader started at #{Time.now.to_s}."
puts "Series file (DML) = #{file}"
puts "Import into = #{output_format}"
puts "DSD name (xml) = #{key_family}"
puts v_break_line

export_file = File.open("result/"+file+"_"+output_format+"_dml", "w")
export_file.puts v_dml_header
export_file.puts v_comment + v_break_line
export_file.puts v_comment + "Series Loader started at #{Time.now.to_s}."
export_file.puts v_comment + "Series file (DML) = #{file}"
export_file.puts v_comment + "Import into = #{output_format}"
export_file.puts v_comment + "DSD name (xml) = #{key_family}"
export_file.puts v_comment + v_break_line

############################################################################################
#Series
puts "\n" + 'Series ... '					
export_file.puts "\n" + v_comment + 'Series'
v_elementi_col = ''
v_elementi_val = ''
v_table = "F_OBSERVATIONS"
arr_series = [] 

#Create INSERT statement for table F_OBSERVATIONS
Xml::Parser.new(Nokogiri::XML::Reader(open(file))) do    		
	for_element 'na_:Series' do		
	#for_element 'jvs:Series' do		
	#for_element 'Series' do		
		tmp = @node.attributes			
		#puts name			
		inside_element do
			for_element 'na_:Obs' do
			#for_element 'jvs:Obs' do
			#for_element 'Obs' do	
				tmp = tmp.merge @node.attributes 								
				arr_series.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]								
			end
		end								
	end				
 end
 puts 'OK'
  
 puts 'Create INSERT statement'
 export_file.puts "\n"
 arr_series.each_with_index do |f, ind2|							
		export_file.puts v_dml_prefix + 'INSERT INTO '+v_table+'_STAGE ('+f.map{|fi| "_"+fi[0]+"_ID" }.join(", ")+') VALUES (\''+f.map{|fi| fi[1] }.join("\', \'")+'\');'+ v_dml_sufix0 + "\n" + v_dml_sufix		
 end
 puts 'OK' 
# Series - end


############################################################################################
#Create composite key
arr_dim = [] 
Xml::Parser.new(Nokogiri::XML::Reader(open(key_family))) do    		
	for_element 'str:Dimension' do		
		tmp = @node.attributes		
		inside_element do
			for_element 'str:TextFormat' do	
				tmp = tmp.merge @node.attributes			
				arr_dim.push Hash[tmp.map{|sym| [sym[0], sym[1].to_s]}]								
			end
		end										
	end	
end 
export_file.puts  'UPDATE '+v_table+'_STAGE SET composite_key = '+arr_dim.map { |x| "_"+x["conceptRef"]+"_ID"}.join("||'.'||") + ';'

puts "\n" + 'tmp - direct load from Stage to Fact'					
export_file.puts "\n" + v_comment + 'tmp - direct load from Stage to Fact'
export_file.puts 'INSERT INTO '+v_table + ' SELECT * FROM '+v_table+'_STAGE;'
puts 'OK'
 
# end
puts "\n" + v_break_line
puts "Series Loader finished at #{Time.now.to_s}."
puts "Generated DML file: result/#{file+"_"+output_format+"_dml"}"
puts v_break_line

#zatvaranje datoteke za DML
export_file.puts "\n" + v_comment + v_break_line
export_file.puts v_comment + "Series Loader finished at #{Time.now.to_s}."
export_file.puts v_comment + "Generated DML file: #{file+"_"+output_format+"_dml"}"
export_file.puts v_comment + v_break_line
export_file.puts v_dml_footer
export_file.close