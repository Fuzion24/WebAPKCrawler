require 'rubygems'
require 'digest/sha1'
require 'zip/zip'
require 'fileutils'

	def hash_file(file_name)
		buffer_size = 1024
		hash_func = Digest::SHA1.new
		open(file_name, "r") do |io|
				counter = 0
				while (!io.eof)
					readBuf = io.readpartial(buffer_size)
					hash_func.update(readBuf)
				end
		end
		return hash_func.hexdigest
	end

    def valid_apk(file)
        #should be a zip file and contain the following
        #resources.arsc
        #AndroidManifest.xml
        #classes.dex
        #this function should eventually use some of dalvik/validator to check the dex file structure - Similar to when an application is installed on Android
     	begin
        apk_zip = Zip::ZipFile.open(file)
		rescue => ex
			puts "Failed on #{file}"
			return false
		end
       	return false if apk_zip.find_entry("classes.dex").nil?
        return false if apk_zip.find_entry("AndroidManifest.xml").nil?
        return false if apk_zip.find_entry("resources.arsc").nil?
        return true
    end 


def is_zip(file_name)
	result = `file "#{file_name}"`
	if result =~ /Zip archive data/
		return true
	else
		return false
	end
end


def move_and_rename(src, dst)
 scandir = "#{src}/*"
 Dir[scandir].sort.each do |name|
 	if (not File.directory? name) and (is_zip(name)) and valid_apk(name)
 		h1 = hash_file name
 		FileUtils.mv(name, "#{dst}/#{h1}.apk")
 	end
 end
end

move_and_rename "/Volumes/Ext/Downloads/apks", 
"/Users/fuzion24/Development/apkcrawler/downloads/"