require File.join(File.dirname(__FILE__), 'test_helper')
require 'uri'
require 'curb'
require 'timeout'

class UriMetaTest < Test::Unit::TestCase
  # First things first. Purge all test URIs on the metauri service so we don't
  # get issues from old cached URIs.
  [
    'garbage',
    'http://bit.ly/PBzu',
    'http://bit.ly/rvQhW',
    'http://digg.com/educational/Can_you_teach_men_who_pick_up_prostitutes_not_to_buy_sex',
    'http://img11.yfrog.com/i/vaix.jpg/',
    'http://imgur.com/GTgb4',
    'http://rss.slashdot.org/Slashdot/slashdot',
    'http://slashdot.org/',
    'http://taptaptap.com/+MqN',
    "http://#{URI::Meta.service_host}/",
    "http://#{URI::Meta.service_host}/double_redirect_test",
    "http://#{URI::Meta.service_host}/#foo",
    "http://#{URI::Meta.service_host}/foo%5Bbar%5D",
    "http://#{URI::Meta.service_host}/meta_redirect_test",
    "http://#{URI::Meta.service_host}/redirect_test",
    'http://www.facebook.com/home.php',
    'http://www.facebook.com/pages/Bronx-NY/Career-and-Transfer-Services-at-BCC/113334355068',
    'http://www.google.com:666/',
    'http://www.stumbleupon.com/s/#4sDy2p/sivers.org/hellyeah',
    'http://www.taobao.com/',
    'http://www.youtube.com/das_captcha?next=/watch%3Fv%3DQ1rdsFuNIMc',
  ].each{|uri| Curl::Easy.http_get("http://#{URI::Meta.service_host}/delete?uri=#{URI.escape(uri.to_s, URI::Meta::UNSAFE)}") }

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

      context '.content_type' do
        should 'be text/html' do
          assert_equal 'text/html', @meta.content_type
        end
      end

      context '.charset' do
        should 'be utf-8' do
          assert_equal 'utf-8', @meta.charset
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

  context %Q(URI.parse('http://#{URI::Meta.service_host}/redirect_test')) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/redirect_test")
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

  context %Q(URI.parse('http://#{URI::Meta.service_host}/double_redirect_test')) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/double_redirect_test")
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

    should 'return an array of 2' do
      assert_kind_of Array, @return_metas
      assert_equal 2, @return_metas.size
    end

    should 'all be URI::Meta objects' do
      assert @return_metas.all?{|m| m.kind_of? URI::Meta}
    end

    should 'contain a google meta' do
      assert @return_metas.any?{|m| m.title == 'Google'}
    end

    context 'yielded in block' do
      should '2 URI::Meta objects' do
        assert @block_metas.all?{|m| m.kind_of? URI::Meta}
        assert_equal 2, @return_metas.size
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

    should 'not have a feed' do
      assert_nil @meta.feed
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

  context %q(URI.parse('http://www.youtube.com/das_captcha?next=/watch%3Fv%3DQ1rdsFuNIMc')) do
    setup do
      @uri = URI.parse('http://www.youtube.com/das_captcha?next=/watch%3Fv%3DQ1rdsFuNIMc')
      @meta = @uri.meta
    end

    should 'obtain the correct title through captcha' do
      assert_equal 'YouTube - Legolibrium', @meta.title
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
      assert_not_equal '', @meta.title
    end
  end

  context %q(URI.parse('http://www.facebook.com/pages/Bronx-NY/Career-and-Transfer-Services-at-BCC/113334355068').meta) do
    setup do
      @meta = URI.parse('http://www.facebook.com/pages/Bronx-NY/Career-and-Transfer-Services-at-BCC/113334355068').meta
    end

    should 'have a title' do
      assert_not_nil @meta.title
      assert_not_equal '', @meta.title
    end
  end

  context %Q(URI.parse("http://#{URI::Meta.service_host}/meta_redirect_test").meta) do
    setup do
      @uri = URI.parse("http://#{URI::Meta.service_host}/meta_redirect_test")
      @meta = @uri.meta
    end

    should 'be a redirect' do
      assert @meta.redirect?
    end

    should 'keep the original URL intact' do
      assert_equal @uri.to_s, @meta.uri.to_s
    end
  end

  context %Q(URI.parse('http://slashdot.org/').meta) do
    setup do
      @meta = URI.parse('http://slashdot.org/').meta
    end

    should 'have a feed' do
      assert_equal 'http://rss.slashdot.org/Slashdot/slashdot', @meta.feed.to_s
    end
  end

  context %Q(URI.parse('http://rss.slashdot.org/Slashdot/slashdot').meta) do
    setup do
      @meta = URI.parse('http://rss.slashdot.org/Slashdot/slashdot').meta
    end

    should 'have a feed equal to itself'
  end

  context %Q(URI.parse('http://digg.com/educational/Can_you_teach_men_who_pick_up_prostitutes_not_to_buy_sex').meta) do
    setup do
      @meta = URI.parse('http://digg.com/educational/Can_you_teach_men_who_pick_up_prostitutes_not_to_buy_sex').meta
    end

    context '.content_type' do
      should 'be text/html' do
        assert_equal 'text/html', @meta.content_type
      end
    end

    context '.charset' do
      should 'be UTF-8' do
        assert @meta.charset.match(/^utf-8$/i)
      end
    end
  end

  context %Q(URI.parse('http://imgur.com/GTgb4').meta) do
    setup do
      @meta = URI.parse('http://imgur.com/GTgb4').meta
    end

    should 'be a redirect' do
      assert @meta.redirect?
      assert_not_equal 'http://imgur.com/GTgb4', @meta.last_effective_uri
    end
  end
end
