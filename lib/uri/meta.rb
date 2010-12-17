require 'uri'
require 'curb'
require 'yaml'
require 'moneta'
require 'moneta/memory'
require 'digest/sha1'
require 'zlib'

module URI
  class Meta
    attr_accessor :headers, :uri, :title, :feed, :last_modified, :content_type, :charset, :last_effective_uri, :status, :errors
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
        case k.to_sym
          when :last_effective_uri, :uri, :feed then send("#{k}=", v.to_s == '' ? nil : (URI.parse(v.to_s) rescue nil))
          when :error, :errors                  then self.errors.push(*[v].flatten)
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

    def self.cache_key(uri, options = {})
      # Make sure the key includes the options used to retrieve the meta
      uid = uri.to_s + options.to_a.sort{|a,b| a[0].to_s <=> b[0].to_s}.to_s
      Digest::SHA1.hexdigest(uid)
    end

    #--
    # TODO: Chunk uri's through a pre-warmed pool of curl easy instances?
    def self.multi(uris, options = {}, &block)
      metas = []
      multi = Curl::Multi.new
      uris.each do |uri|
        if meta = URI::Meta::Cache.get(cache_key(uri, options))
          metas << meta
          URI::Meta::Cache.store(cache_key(uri, options), meta)
          block.call(meta) if block
        else
          easy = curl(uri, options)
          easy.on_complete do |req|
            args = YAML.load(self.decode_content(req)) rescue {:errors => "YAML Error, #{$!.message}"}
            args = {:errors => "YAML Error, server returned unknown format."} unless args.is_a?(Hash)

            metas << meta = URI::Meta.new({:uri => uri}.update(args))
            URI::Meta::Cache.store(cache_key(uri, options), meta)
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
        options = options.update(:uri => uri)
        options = options.map{|k, v| "#{k}=" + URI.escape(v.to_s, UNSAFE)}.join('&')
        c = Curl::Easy.new("http://#{service_host}/show.yaml?#{options}")
        c.headers['User-Agent']      = user_agent
        c.headers['Accept-encoding'] = 'gzip,deflate'
        c
      end

      def self.decode_content(request)
        if request.header_str.match(/Content-Encoding: gzip/)
          begin
            gz = Zlib::GzipReader.new(StringIO.new(request.body_str))
            yaml = gz.read
            gz.close
          rescue Zlib::GzipFile::Error => e
            yaml = request.body_str
          end
        else
          yaml = request.body_str
        end
        yaml
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
        def store(uid, obj)
          @@cache.store(uid, obj, :expires_in => @@expires_in) unless @@cache.nil?
        end

        def get(id)
          @@cache[id] unless @@cache.nil?
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
