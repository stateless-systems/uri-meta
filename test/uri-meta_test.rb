require File.join(File.dirname(__FILE__), 'test_helper')
require 'uri'
require 'curb'
require 'timeout'

class URIMetaTestCache
  def [](key)
    Curl::Easy.http_get("http://#{URI::Meta.service_host}/delete?uri=#{URI.escape(key.to_s, URI::Meta::UNSAFE)}")
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
  context %Q(URI.parse('http://#{URI::Meta.service_host}/')) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/")
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
    end

    context '.meta(:headers => 1)' do
      setup do
        @meta = URI.parse("http://#{URI::Meta.service_host}/").meta(:headers => 1)
      end

      context '.headers' do
        should 'be populated' do
          assert_not_nil @meta.headers
        end
      end
    end
  end

  context %Q(URI.parse('http://#{URI::Meta.service_host}/redirect')) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/redirect")
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

  context %Q(URI.parse('http://#{URI::Meta.service_host}'/double_redirect)) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/double_redirect")
    end

    context '.meta(:max_redirects => 1)' do
      should 'error on too many redirects' do
        meta = @uri.meta(:max_redirects => 1)
        assert meta.errors?
        assert_kind_of String, meta.errors.first
      end
    end
  end

  context %q{URI.parse('http://bit.ly/rvQhW').meta} do
    should 'raise nothing' do
      assert_nothing_raised do
        URI.parse('http://bit.ly/rvQhW').meta
      end
    end
  end

  context %q(URI.parse('garbage').meta) do
    should 'raise errors' do
      assert_raise NotImplementedError do
        URI.parse('garbage').meta
      end
    end
  end

  context %q(URI.parse('http://bit.ly/PBzu').meta) do
    setup do
      @meta = URI.parse('http://bit.ly/PBzu').meta
    end

    should 'be a redirect' do
      assert @meta.redirect?
      assert_not_equal 'http://bit.ly/PBzu', @meta.last_effective_uri
    end
  end

  context %q(URI.parse('http://taptaptap.com/+MqN').meta) do
    setup do
      @uri = URI.parse('http://taptaptap.com/+MqN')
    end

    should 'escape the + symbol' do
      assert_nothing_raised do
        @meta = @uri.meta
      end
      assert !@meta.errors?
    end
  end

  context %Q(URI::Meta.multi(['http://www.google.com/', "http://#{URI::Meta.service_host}/"])) do
    setup do
      @metas = URI::Meta.multi(['http://www.google.com/', "http://#{URI::Meta.service_host}/"])
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

  context %Q(URI::Meta.multi(['http://www.google.com/', "http://#{URI::Meta.service_host}/"]) {}) do
    setup do
      @block_metas = []
      @return_metas = URI::Meta.multi(['http://www.google.com/', "http://#{URI::Meta.service_host}/"]) do |meta|
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

  context %q(URI.parse('http://www.google.com:666/')) do
    setup do
      @uri = URI.parse('http://www.google.com:666/')
    end

    context '.meta' do
      should 'not return within 5 seconds' do
        begin
          timeout(5) do
            meta = @uri.meta
            assert false
          end
        rescue Timeout::Error => e
          assert true
        end
      end
    end

    context '.meta(:connect_timeout => 1)' do
      should 'return before 5 seconds' do
        begin
          timeout(5) do
            meta = @uri.meta(:connect_timeout => 1)
            assert true
          end
        rescue Timeout::Error => e
          assert false
        end
      end

      should 'contain timeout errors' do
        assert @uri.meta(:connect_timeout => 1).errors?
      end
    end
  end

  context %Q(URI.parse('http://#{URI::Meta.service_host}/#foo').meta) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/#foo")
      @meta = @uri.meta
    end

    should 'keep # info intact' do
      assert_equal @uri.to_s, @meta.uri.to_s
    end
  end

  context %q(URI.parse('http://www.taobao.com/').meta) do
    setup do
      @uri = URI.parse('http://www.taobao.com/')
    end

    should 'not die from UTF8 issues' do
      assert_nothing_raised do
        @meta = @uri.meta
      end
      assert !@meta.errors?
    end
  end

  context %q(URI.parse('http://www.stumbleupon.com/s/#4sDy2p/sivers.org/hellyeah').meta) do
    setup do
      @uri = URI.parse('http://www.stumbleupon.com/s/#4sDy2p/sivers.org/hellyeah')
      @meta = @uri.meta
    end

    should 'be a redirect' do
      assert @meta.redirect?
    end

    should 'not end at stumble upon' do
      assert @meta.last_effective_uri !~ /stumble/
    end
  end

  context %q(URI.parse('http://www.youtube.com/das_captcha?next=/watch%3Fv%3DuP6fEVR87Uo')) do
    setup do
      @uri = URI.parse('http://www.youtube.com/das_captcha?next=/watch%3Fv%3DuP6fEVR87Uo')
      @meta = @uri.meta
    end

    should 'obtain the correct title through captcha' do
      assert_equal 'YouTube - I Love You, Man - Lonnie The Voice Crack Guy', @meta.title
    end

    should 'not have changed the last_effective_uri' do
      assert_equal @uri.to_s, @meta.uri.to_s
    end
  end

  context %q(URI.parse('http://www.facebook.com/home.php')) do
    setup do
      @meta = URI.parse('http://www.facebook.com/home.php').meta
    end

    should 'correctly return 403' do
      assert_equal 403, @meta.status
    end
  end

  context %Q(URI.parse("http://#{URI::Meta.service_host}/foo%5Bbar]")) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/foo%5Bbar%5D")
      @meta = @uri.meta
    end

    should 'keep encoded square brackets intact' do
      assert_equal @uri.to_s, @meta.uri.to_s
    end
  end

  context %q(URI.parse('http://img11.yfrog.com/i/vaix.jpg/').meta) do
    setup do
      @meta = URI.parse('http://img11.yfrog.com/i/vaix.jpg/').meta
    end

    should 'have a content type' do
      assert_not_nil @meta.content_type
    end

    should 'have a title' do
      assert_not_nil @meta.title
    end
  end
end
