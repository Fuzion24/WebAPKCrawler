require 'rubygems'
require 'net/http'
require 'digest/sha1'
require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'typhoeus'

class ApkCrawler

	def initialize
		@state_file = File.join(File.dirname(__FILE__), "url_search_state.yml")
		@url_match_state = YAML.load_file(@state_file)
	end

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

	def hash_str(str)
		hash_func = Digest::SHA1.new
		hash_func.update(str)
		return hash_func.hexdigest
	end

	def download_apks_from_page(url)
		begin
			doc = Nokogiri::HTML(open(URI.escape(url)))
		rescue => ex
			puts "#{ex.message} #{url}"
			return
		end
		doc.css('a').each do |link|
		  if link['href'] =~ /\b.+.\.apk/
		    begin
		        download_file = open(url+link['href'])
		        downloaded_file = download_file.read()
		        h1 = hash_str downloaded_file
		        puts "#{h1} NEW #{link['href']}" if not File.exists? "downloads/#{h1}.apk"
		        puts "#{h1} #{link['href']}" if File.exists? "downloads/#{h1}.apk"
		        if not File.exists? "downloads/#{h1}.apk"
			      	File.open("downloads/#{h1}.apk",'wb') do |file|
			        	file.write(downloaded_file)
			      	end
		      	end
		    rescue => ex
			    puts "Boom goes the dynamite! #{ex.message} \n\n #{ex.backtrace}\n\n #{url+link['href']}"
		    end
		  end
		end
	end

	def save_hash
		File.open(@state_file, "w") do |f|
	       f.write(@url_match_state.to_yaml)
	    end
	end

	def google_results(search_term, result_start=0)
		doc = Nokogiri::HTML(open(URI.escape("http://www.google.com/search?q=#{search_term}&start=#{result_start}")))
		doc.css('li.g h3.r a').map { |link|
            link['href'].scan(/\/url\?q=([a-zA-Z:\/.0-9-]+)/)[0][0]
        }
	end

	def crawl
		@url_match_state.each do |k,v|
			g_results = google_results(k,v)
			g_results.each do |url|
				puts "Searching #{url}"
				download_apks_from_page url
				@url_match_state[k] += 1
				save_hash
			end
		end
	end

end