#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'benchmark'
require 'curb'
require 'uri/meta'

URI::Meta::Cache.cache = nil

cached_uris = uncached_uris = []
uncached_uris = []

delete = Curl::Multi.new

(1..50).each do |x|
  cached_uris << URI.parse('http://tigris.id.au/')
  uncached_uris << URI.parse("http://tigris.id.au/#{x}")
  c = Curl::Easy.new("http://www.metauri.com/delete?uri=#{uncached_uris.last.to_s}")
  c.on_complete{|curl| print '.'}
  delete.add(c)
end

print '   performing cache clear '
clear = Benchmark.realtime{ delete.perform }
puts " #{clear}"

## TODO: figure out why uncached is faster when X > pool size, but way less when X < pool size
print '  calculating cached time '
cached = Benchmark.realtime{ URI::Meta.multi(cached_uris){|m| print '.'}}
puts " #{cached}"

print 'calculating uncached time '
uncached = Benchmark.realtime{ URI::Meta.multi(uncached_uris){|m| print '.'}}
puts " #{uncached}"
