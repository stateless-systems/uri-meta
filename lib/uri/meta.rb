require 'uri'
require 'curb'
require 'yaml'

module URI
  module Mixin
    module Meta
      def meta
        @meta ||= URI::Meta.new(self)
      end
    end
  end

  class Meta
    attr_accessor :headers, :content, :uri, :title, :last_modified, :content_type, :charset

    def initialize(uri)
      retrieve!(uri.to_s)
    end

    protected
      def retrieve!(uri)
        curl = Curl::Easy.new('http://staging.metauri.com/show.yaml?uri=' + uri)
        curl.perform
        populate_from_yaml!(YAML.load(curl.body_str))
      end

      def populate_from_yaml!(yaml)
        yaml[:uri] = URI.parse(yaml[:uri])
        yaml.each{|p| send("#{p[0]}=", p[1]) if respond_to?("#{p[0]}=")}
      end
  end

  URI::Generic.send(:include, URI::Mixin::Meta)
  URI::HTTP.send(:include, URI::Mixin::Meta)
end
