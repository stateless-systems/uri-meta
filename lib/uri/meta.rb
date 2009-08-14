require 'uri'
require 'curb'
require 'yaml'
require 'moneta'
require 'moneta/memory'

module URI
  module Mixin
    module Meta
      def meta
        @meta ||= URI::Meta::Cache.get(self.to_s) || URI::Meta.new(self)
        URI::Meta::Cache.store(self.to_s, @meta)
      end
    end
  end

  class Meta
    class Error < ::RuntimeError; end
    attr_accessor :headers, :content, :uri, :title, :last_modified, :content_type, :charset

    def initialize(uri)
      uri = URI.parse(uri.to_s) rescue nil
      raise URI::InvalidURIError.new if uri.nil? or !uri.is_a?(URI::HTTP)
      retrieve!(uri.to_s)
    end

    protected
      def retrieve!(uri)
        curl = Curl::Easy.new('http://www.metauri.com/show.yaml?uri=' + URI.escape(uri, URI::REGEXP::PATTERN::RESERVED))
        curl.perform
        populate_from_yaml!(YAML.load(curl.body_str))
      end

      def populate_from_yaml!(yaml)
        raise Error.new(yaml[:error]) if yaml[:error]
        yaml[:uri] = URI.parse(yaml[:uri]) rescue yaml[:uri]
        yaml.each{|p| send("#{p[0]}=", p[1]) if respond_to?("#{p[0]}=")}
      end

    class Cache
      @@cache      = Moneta::Memory.new
      @@expires_in = 86_400 # 24 hours

      class << self
        def store(key, url)
          @@cache.store(key, url, :expires_in => @@expires_in) unless @@cache.nil?
        end

        def get(key)
          @@cache[key] unless @@cache.nil?
        end

        def cache=(cache)
          warn 'Turning off caching is poor form, for longer processes consider using moneta/memcached' if cache.nil?
          @@cache = cache
        end

        def expires_in=(seconds)
          @@expires_in = seconds
        end
      end
    end
  end

  URI::Generic.send(:include, URI::Mixin::Meta)
  URI::HTTP.send(:include, URI::Mixin::Meta)
end
