require 'rubygems'
require 'fileutils'
require File.join(File.dirname(__FILE__), "apkcrawler")

FileUtils::mkdir_p 'downloads'
ApkCrawler.new.crawl
