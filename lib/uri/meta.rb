require 'uri'
require 'curb'
require 'yaml'
require 'moneta'
require 'moneta/memory'

module URI
  module Mixin
    module Meta
      def meta(opts = {})
        @meta ||= URI::Meta::Cache.get(self.to_s) || URI::Meta.new(opts.merge(:uri => self))
        URI::Meta::Cache.store(self.to_s, @meta)
        @meta
      end
    end
  end

  class Meta
    class Error < ::RuntimeError; end
    attr_accessor :headers, :content, :uri, :title, :last_modified, :content_type, :charset, :last_effective_uri, :status

    def initialize(args)
      if args.key? :uri
        raise ArgumentError.new(":uri must be of type URI, not #{args[:uri].class}") unless args[:uri].is_a?(URI)
        populate_from_yaml! retrieve(args[:uri], args)
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

    def self.multi(uris, opts = {})
      metas = []
      responses = {}
      curl_multi = Curl::Multi.new
      uris.each do |uri|
        if meta = URI::Meta::Cache.get(uri.to_s)
          metas << meta
        else
          curl = curl(uri, opts)
          responses[uri.to_s] = ''
          curl.on_body{|y| responses[uri.to_s] << y; y.size}
          curl_multi.add curl
        end
      end
      curl_multi.perform
      responses.each do |k,v|
        meta = new(:yaml => YAML.load(v))
        URI::Meta::Cache.store(k, meta)
        metas << meta
      end
      metas.each{|m| yield m} if block_given?
      metas
    end

    protected
      def self.curl(uri, opts = {})
        curl_options = {:uri => uri}.merge(opts.reject{|k,v| k == :uri})
        Curl::Easy.new('http://www.metauri.com/show.yaml?' + curl_options_to_string(curl_options))
      end

      def self.curl_options_to_string(opts)
        opts.to_a.map{|x| x[0].to_s + '=' + URI.escape(x[1].to_s, URI::REGEXP::PATTERN::RESERVED)}.join('&')
      end

      def retrieve(uri, opts = {})
        raise NotImplementedError.new('Only HTTP is supported so far.') unless uri.is_a?(URI::HTTP)
        curl = self.class.curl(uri, opts)
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
