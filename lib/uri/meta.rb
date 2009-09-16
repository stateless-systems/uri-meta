require 'uri'
require 'curb'
require 'yaml'
require 'moneta'
require 'moneta/memory'

module URI
  class Meta
    attr_accessor :headers, :uri, :title, :last_modified, :content_type, :charset, :last_effective_uri, :status, :errors
    @@service_host = 'www.metauri.com'
    @@user_agent   = 'uri-meta rubygem'

    UNSAFE = Regexp.new("[#{URI::REGEXP::PATTERN::RESERVED} #%]", false, 'N').freeze

    def self.service_host
      @@service_host
    end

    def self.service_host=(service_host)
        @@service_host = service_host
    end

    def self.user_agent
      @@user_agent
    end

    def self.user_agent=(user_agent)
        @@user_agent = user_agent
    end

    def initialize(options = {})
      self.errors = []
      options.each do |k, v|
        case k
          when :last_effective_uri, :uri then send("#{k}=", (URI.parse(v.to_s) rescue nil))
          when :error, :errors           then self.errors.push(*[v].flatten)
          else send("#{k}=", v) if respond_to?("#{k}=")
        end
      end
    end

    def redirect?
      uri != last_effective_uri
    end

    def errors?
      !errors.empty?
    end

    def self.get(uri, options = {})
      uri = URI.parse(uri.to_s) rescue nil
      raise ArgumentError.new("Can't coerce #{uri.class} to URI") unless uri.is_a?(URI)
      raise NotImplementedError.new('Only HTTP is supported so far.') unless uri.is_a?(URI::HTTP)
      URI::Meta.multi([uri], options).first
    end

    #--
    # TODO: Chunk uri's through a pre-warmed pool of curl easy instances?
    def self.multi(uris, options = {}, &block)
      metas = []
      multi = Curl::Multi.new
      uris.each do |uri|
        if meta = URI::Meta::Cache.get(uri.to_s)
          metas << meta
          URI::Meta::Cache.store(uri.to_s, meta)
          block.call(meta) if block
        else
          easy = curl(uri, options)
          easy.on_complete do |curl|
            args = YAML.load(curl.body_str) rescue {:errors => "YAML Error, #{$!.message}"}
            args = {:errors => "YAML Error, server returned unknown format."} unless args.is_a?(Hash)

            metas << meta = URI::Meta.new({:uri => uri}.update(args))
            URI::Meta::Cache.store(uri.to_s, meta)
            block.call(meta) if block
          end
          multi.add(easy)
        end
      end
      multi.perform
      metas
    end

    protected
      #--
      # Required because the URI option must be verbatim. If '+' and others are not escaped Merb, Rack or something
      # helpfully converts them to spaces on metauri.com
      def self.curl(uri, options = {})
        options = options.update(:uri => uri, :user_agent => user_agent)
        options = options.map{|k, v| "#{k}=" + URI.escape(v.to_s, UNSAFE)}.join('&')
        Curl::Easy.new("http://#{service_host}/show.yaml?#{options}")
      end

    module Mixin
      def meta(options = {})
        @meta ||= URI::Meta.get(self, options)
      end
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

  URI::Generic.send(:include, URI::Meta::Mixin)
  URI::HTTP.send(:include, URI::Meta::Mixin)
end
