require 'test_helper'
require 'uri'
require 'curb'

class URIMetaTestCache
  def [](key)
    Curl::Easy.http_get('http://www.metauri.com/delete?uri=' + URI.escape(key.to_s, URI::REGEXP::PATTERN::RESERVED))
    nil
  end

  def store(key, value, opts = {}); end
  def expires_in(seconds); end
end

# For testing, lets hack up a cache mechanism that will force delete a URI from
# metauri.com everytime we want meta info, so not only is it not cached here,
# it's also not cached out there!
URI::Meta::Cache.cache = URIMetaTestCache.new

class UriMetaTest < Test::Unit::TestCase
  context 'URI.parse(http://www.metauri.com/)' do
    setup do
      @uri = URI.parse('http://www.metauri.com/')
    end

    should 'respond_to :meta' do
      assert_respond_to @uri, :meta
    end

    context '.meta' do
      setup do
        @meta = @uri.meta
      end

      should 'be a URI::Meta object' do
        assert_kind_of URI::Meta, @meta
      end

      context '.uri' do
        should 'be a URI object' do
          assert_kind_of URI, @meta.uri
        end

        should 'be the same as the original URI' do
          assert_equal @uri.to_s, @meta.uri.to_s
        end
      end

      context '.last_effective_uri' do
        should 'be a URI object' do
          assert_kind_of URI, @meta.last_effective_uri
        end

        should 'not have been a redirect' do
          assert_equal @uri.to_s, @meta.last_effective_uri.to_s
          assert !@meta.redirect?
        end
      end

      context '.title' do
        should 'be Meta URI' do
          assert_equal 'Meta URI', @meta.title
        end
      end

      context '.status' do
        should 'be 200' do
          assert_equal 200, @meta.status
        end
      end

      context '.headers' do
        should 'be nil' do
          assert_nil @meta.headers
        end
      end

      context '.content' do
        should 'be nil' do
          assert_nil @meta.content
        end
      end
    end

    context '.meta(:content => 1)' do
      setup do
        @meta = @uri.meta(:content => 1)
      end

      context '.content' do
        should 'be populated' do
          assert_not_nil @meta.content
        end
      end

      context '.headers' do
        should 'be nil' do
          assert_nil @meta.headers
        end
      end
    end

    context '.meta(:headers => 1)' do
      setup do
        @meta = @uri.meta(:headers => 1)
      end

      context '.headers' do
        should 'be populated' do
          assert_not_nil @meta.headers
        end
      end

      context '.content' do
        should 'be nil' do
          assert_nil @meta.content
        end
      end
    end
  end

  context 'URI.parse(http://www.metauri.com/redirect)' do
    setup do
      @uri = URI.parse('http://www.metauri.com/redirect')
    end

    context '.meta' do
      context '.last_effective_uri' do
        should 'be a redirect' do
          assert_not_equal @uri.to_s, @uri.meta.last_effective_uri.to_s
          assert @uri.meta.redirect?
        end
      end
    end
  end

  context 'URI.parse(http://www.metauri.com/double_redirect)' do
    setup do
      @uri = URI.parse('http://www.metauri.com/double_redirect')
    end

    context '.meta(:max_redirects => 1)' do
      should 'raise error on too many redirects' do
        assert_raise URI::Meta::Error do
          @uri.meta(:max_redirects => 1)
        end
      end
    end
  end

  context 'URI.parse(garbage).meta' do
    should 'raise errors' do
      assert_raise NotImplementedError do
        URI.parse('garbage').meta
      end
    end
  end

  context 'URI.parse(http://bit.ly/PBzu).meta' do
    setup do
      @uri = URI.parse('http://bit.ly/PBzu')
    end

    should 'be a redirect' do
      assert_not_equal 'http://bit.ly/PBzu', @uri.meta.last_effective_uri
    end
  end

  context 'URI.parse(http://taptaptap.com/+MqN).meta' do
    setup do
      @uri = URI.parse('http://taptaptap.com/+MqN')
    end

    should 'escape the + symbol' do
      assert_nothing_raised do
        @uri.meta
      end
    end
  end

  context 'URI.parse(http://bit.ly/QYKrH).meta' do
    should 'raise error on too many redirects' do
      assert_raise URI::Meta::Error do
        URI.parse('http://bit.ly/QYKrH').meta
      end
    end
  end

  context 'URI::Meta.multi([http://www.google.com/, http://www.metauri.com/])' do
    setup do
      @metas = URI::Meta.multi(['http://www.google.com/', 'http://www.metauri.com/'])
    end

    should 'return an array' do
      assert_kind_of Array, @metas
    end

    should 'all be URI::Meta objects' do
      assert @metas.all?{|m| m.kind_of? URI::Meta}
    end

    should 'contain a google meta' do
      assert @metas.any?{|m| m.title == 'Google'}
    end
  end

  context 'URI::Meta.multi([http://www.google.com/, http://www.metauri.com/]) {}' do
    setup do
      @block_metas = []
      @return_metas = URI::Meta.multi(['http://www.google.com/', 'http://www.metauri.com/']) do |meta|
        @block_metas << meta
      end
    end

    should 'return an array' do
      assert_kind_of Array, @return_metas
    end

    should 'all be URI::Meta objects' do
      assert @return_metas.all?{|m| m.kind_of? URI::Meta}
    end

    should 'contain a google meta' do
      assert @return_metas.any?{|m| m.title == 'Google'}
    end

    context 'yielded in block' do
      should 'all URI::Meta objects' do
        assert @block_metas.all?{|m| m.kind_of? URI::Meta}
      end

      should 'a google meta' do
        assert @block_metas.any?{|m| m.title == 'Google'}
      end
    end
  end
end
