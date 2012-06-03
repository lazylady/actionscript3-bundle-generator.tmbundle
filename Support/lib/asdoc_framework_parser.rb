#!/usr/bin/env ruby -wKU
# encoding: utf-8

require "#{ENV['TM_SUPPORT_PATH']}/lib/escape"
require "#{ENV['TM_BUNDLE_SUPPORT']}/lib/asdoc_tidy"

require 'rubygems'
require 'nokogiri'

# Deserialises the asdoc generated all-classes.html file into a object that is
# then serialized into a TextMate Bundle. Children are handled by the 
# AsdocClassParser class.
#
class AsdocFrameworkParser

  LINK_X_PATH = "//html/body/div/a"
  NAME_X_PATH = "//html/head/title"

  private

    def initialize
      @class_path_list = []
      @doc_path_list = []
      @framework_name = "unknown"
      @package_filter = /^/
      @logging_enabled = false
    end

  public

    # Getter/Setters
    attr_reader :class_path_list
    attr_reader :doc_path_list
    
    attr_writer :package_filter
    attr_writer :logging_enabled

    # Commands

    # Load the all-classes.html document and create
    # a list of it's contents.
    def load_framework all_classes_html
      
      @base_uri = File.dirname all_classes_html
      
      f = File.open(all_classes_html)
      class_doc = Nokogiri::HTML(f)
      
      # TODO: Class path level filtering.
      class_doc.xpath(LINK_X_PATH).each() do |tag|
        class_href = tag.get_attribute('title').to_s
        
        if class_href =~ @package_filter
          class_href = class_href.gsub(".", "/")
          file_path = @base_uri+"/" + class_href + ".html"
          
          @class_path_list.push( file_path )
          # remove whitspace
          class_name = tag.text.strip
          class_name.gsub!("\302\240", '')
          doc_tag = "<a href='#{class_href}.html'>#{class_name}</a>"
          @doc_path_list.push( doc_tag )
        end
      end

      class_doc.xpath(NAME_X_PATH).each() do |tag|
        begin
          # All Classes - ActionScript 3.0 Language and Components Reference
          # All Classes \- \b(\w+)\b API Documentation
          title_match = /All Classes \- \b(\w+)\b/
          @framework_name = title_match.match( tag[0].to_s )[1].downcase
        rescue Exception => e
          puts e.to_s
        end
      end

    end

    # Generates an asdoc dictionary list file this can be used
    # by asdoc.rb search script.
    def asdoc_dictionary

      return nil if @class_path_list.empty?

      xml =  '<?xml version="1.0" encoding="UTF-8"?>'
      xml += "\n<dict>\n"

      #TODO: Refactor to use single path array by reconstructing original
      #path here.
      @doc_path_list.each do |tag|
        xml += "\t"+tag+"\n"
      end

      xml += '</dict>'

    end

    # The name of the framework as parsed from the html title.
    def framework_name
      @framework_name
    end

    # Log output.
    def log( message )
      if @logging_enabled
        require 'syslog'
        
        Syslog.open('as3-bundle-gen')
        Syslog.crit(message)
        Syslog.close()
      end
    end

end
