require 'uri'
require 'curb'
require 'yaml'
require 'moneta'
require 'moneta/memory'

module URI
  module Mixin
    module Meta
      def meta
        @meta ||= URI::Meta::Cache.get(self.to_s) || URI::Meta.new(:uri => self)
        URI::Meta::Cache.store(self.to_s, @meta)
      end
    end
  end

  class Meta
    class Error < ::RuntimeError; end
    attr_accessor :headers, :content, :uri, :title, :last_modified, :content_type, :charset, :last_effective_uri

    def initialize(args)
      if args.key? :uri
        raise ArgumentError.new(":uri must be of type URI, not #{args[:uri].class}") unless args[:uri].is_a?(URI)
        populate_from_yaml! retrieve(args[:uri])
      elsif args.key? :yaml
        raise ArgumentError.new(":yaml must be of type Hash, not #{args[:yaml].class}") unless args[:yaml].is_a?(Hash)
        populate_from_yaml! args[:yaml]
      else
        raise ArgumentError.new('Required argument :yaml or :uri was missing')
      end
    end

    def redirect?
      uri != last_effective_uri
    end

    def populate_from_yaml!(yaml)
      raise Error.new(yaml[:error]) if yaml[:error]
      yaml[:uri] = URI.parse(yaml[:uri]) rescue yaml[:uri]
      yaml[:last_effective_uri] = URI.parse(yaml[:last_effective_uri]) rescue yaml[:last_effective_uri]
      yaml.each{|p| send("#{p[0]}=", p[1]) if respond_to?("#{p[0]}=")}
    end

    def self.multi(*uris)
      metas = []
      curl_multi = Curl::Multi.new
      uris.each do |uri|
        curl = Curl::Easy.new('http://www.metauri.com/show.yaml?uri=' + URI.escape(uri.to_s, URI::REGEXP::PATTERN::RESERVED))
        curl.on_body do |yaml|
          meta = new(:yaml => YAML.load(yaml))
          metas << meta
          if block_given?
            yield meta
          end
          yaml.size
        end
        curl_multi.add curl
      end
      curl_multi.perform
      metas
    end

    protected
      def retrieve(uri)
        raise NotImplementedError.new('Only HTTP is supported so far.') unless uri.is_a?(URI::HTTP)
        curl = Curl::Easy.new('http://www.metauri.com/show.yaml?uri=' + URI.escape(uri.to_s, URI::REGEXP::PATTERN::RESERVED))
        curl.perform
        YAML.load(curl.body_str)
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
