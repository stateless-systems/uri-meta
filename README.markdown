# uri-meta: Get meta information about your URI

uri-meta is a ruby interface to the [metauri.com](http://www.metauri.com/) service.

[metauri.com](http://www.metauri.com/) provides two things:

 * follows your URI to the end point where there is actual content instead of redirects
 * obtains meta information (title etc) about that end URI

## Examples

    require 'uri'
    require 'uri/meta'
    uri = URI.parse('http://www.google.com/')
    puts uri.meta.title
    # Google
    puts uri.meta.status
    # 200

    uri = URI.parse('http://bit.ly/PBzu')
    puts uri.meta.content_type
    # image/gif

    begin
      meta = URI.parse('http://bit.ly/PBzu').meta(:max_redirects = 1)
    rescue URI::Meta::Error => e
      puts "Oh noes, too many redirects!"
    end

    puts uri.meta.last_effective_uri
    # http://clipart.tiu.edu/offcampus/animated/bd13644_.gif

    URI::Meta.multi(['http://www.google.com/', 'http://bit.ly/PBzu'], :max_redirects => 10) do |meta|
      # Don't rely on these being processed in the same order they were listed!
      if meta.redirect?
        puts "## #{meta.uri} -> #{meta.last_effective_uri}"
      else
        puts "## #{meta.uri} did not redirect and it's title was #{meta.title}"
      end
    end

## Caching

uri-meta uses in-memory caching via [wycats-moneta](http://github.com/wycats/moneta), so it
should be relatively straight forward for you to use whatever other caching mechanism you want,
provided it's supported by moneta.

    require 'uri'
    require 'uri/meta'

    # Memcached
    URI::Meta::Cache.moneta = Moneta::Memcache.new(:server => 'localhost')
    URI::Meta::Cache.expires_in = (60 * 60 * 24 * 7) # 1 week

    # No caching (for testing i guess)
    URI::Meta::Cache.moneta = nil

## Known Issues

 * Redirects that aren't handled by the webserver (302), such as javascript or
   &lt;meta&gt; tag redirects are not supported yet.
 * Framed redirects, such as stumbleupon are not resolved yet, as these are
   techincally full pages it could be difficult to know that it's not really
   then end URI.
 * No RDOC as yet.

# Copyright

Copyright (c) 2009 Stateless Systems. See LICENSE for details.
