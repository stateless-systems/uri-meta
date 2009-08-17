require 'test_helper'

class UriMetaTest < Test::Unit::TestCase
  context 'URI.parse(http://www.metauri.com/)' do
    context '.meta' do
      setup do
        @uri = URI.parse('http://www.metauri.com/')
      end

      should 'exist' do
        assert_respond_to @uri, :meta
      end

      should 'be a URI::Meta object' do
        assert_kind_of URI::Meta, @uri.meta
      end

      context '.uri' do
        should 'be a URI object' do
          assert_kind_of URI, @uri.meta.uri
        end

        should 'be the same as the original URI' do
          assert_equal @uri.to_s, @uri.meta.uri.to_s
        end
      end

      context '.last_effective_uri' do
        should 'be a URI object' do
          assert_kind_of URI, @uri.meta.last_effective_uri
        end

        should 'not have been a redirect' do
          assert_equal @uri.to_s, @uri.meta.last_effective_uri.to_s
          assert !@uri.meta.redirect?
        end
      end

      context '.title' do
        should 'be Meta URI' do
          assert_equal 'Meta URI', @uri.meta.title
        end
      end

      context '.headers' do
        should 'be nil' do
          assert_nil @uri.meta.headers
        end
      end

      context '.content' do
        should 'be nil' do
          assert_nil @uri.meta.content
        end
      end
    end

    context '.meta(:content => true)' do
      context '.content' do
        should 'be populated'
      end

      context '.headers' do
        should 'be nil'
      end
    end

    context '.meta(:headers => true)' do
      context '.headers' do
        should 'be populated'
      end

      context '.content' do
        should 'be nil'
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

  context 'URI::Meta.multi(http://www.google.com/, http://www.metauri.com/)' do
    setup do
      @metas = URI::Meta.multi('http://www.google.com/', 'http://www.metauri.com/')
    end

    should 'return an array' do
      assert_kind_of Array, @metas
    end

    context '.first' do
      should 'be google' do
        assert_equal 'Google', @metas.first.title
      end
    end
  end

  context 'URI::Meta.multi(http://www.google.com/, http://www.metauri.com/) {}' do
    setup do
      @block_metas = []
      @return_metas = URI::Meta.multi('http://www.google.com/', 'http://www.metauri.com/') do |meta|
        @block_metas << meta
      end
    end

    should 'return an array' do
      assert_kind_of Array, @return_metas
    end

    context '.first' do
      should 'be google' do
        assert_equal 'Google', @return_metas.first.title
      end
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
