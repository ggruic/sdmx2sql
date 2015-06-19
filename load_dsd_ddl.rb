# Execute DDL = create DSD relational database
# It's made as an exercise = SO, IT'S VERY SLOW (5-6 minutes per DSD file) - BETTER USE DIRECT LOAD FROM SQLITE3 database ...
# --------------------------------------------------------------------------------
# Args:
# FILE - name of the file with DDL
# BAZA - name of SQLite baze to be created

# example:
# ruby load_dsd_ddl.rb result/NA_SEC+ESTAT+v2_0+1.5.xml_SQLITE_ddl NA_SEC.SQLITE3

###################################################################################################
require_relative "lib/helper_xml"
require 'htmlentities'
coder = HTMLEntities.new
require 'formatador'  
require 'time'
require 'sqlite3'

###################################################################################################
file = nil
baza = nil
key_family = nil
target_file = nil
ARGV.each_with_index do |a, i|  
  if i+1 == 1 then
	file = a
  elsif i+1 == 2 then
	baza = a		
  end
end 
if file.nil? then abort("Enter the name of file with DDL for creating relational database!") end
if baza.nil? then abort("Enter the name of new SQLite database!") end

#check if SQLITE database already exists?
if File.exists?(baza.upcase) then abort "Sqlite3 database named " + baza.upcase + " already exists in this folder!" end

###################################################################################################
#vars	
v_break_line = "----------------------------------------------------------------------------------"
###################################################################################################

#start
Formatador.display('[green]')
system "cls" 
puts v_break_line
puts "-- DSD DDL Loader v1.0 (script for creating SQLite relational database from DDL)"
puts "-- in : file with DDL statements"
puts "-- out: SQLite relational database"
puts v_break_line
puts "DSD DDL Loader started at #{Time.now.to_s}."
puts "Loaded DDL file: #{file}"
puts v_break_line

Formatador.display('[white]')

begin     	
	db = SQLite3::Database.open baza.upcase
	
	puts "\nCreated empty SQLite file: #{baza.upcase}"
    puts "\nProcessed lines from DDL file: "
	
	multi_line = ''	
	File.open(file, "r") do |f|		
		total = f.readlines.size		
		progress = Formatador::ProgressBar.new(total)		
		f.rewind
		
	    f.each_line do |line|			
			if line[0..1] == '--' or line[0..1] == '  ' then
				#skip line with comments and empty line
			else
				multi_line = multi_line + line			
				#execute if complete statement
				if (db.complete? multi_line) then
					db.execute multi_line
					multi_line = ''			
				end
			end
			progress.increment
		end
	end
		
rescue SQLite3::Exception => e     
  
  Formatador.display('[red]')
  puts "\n"+v_break_line
  puts e  
  puts "An error happened during execution of this statement: "  
  puts multi_line
  puts v_break_line
  Formatador.display('[white]')
  abort("\nProcess interrupted!")
    
ensure
   db.close if db
end


# end
Formatador.display('[green]')
puts "\n" + v_break_line
puts "DSD DDL Loader finished at #{Time.now.to_s}."
puts "Created SQLite database named: #{baza.upcase}"
puts v_break_line
Formatador.display('[white]')