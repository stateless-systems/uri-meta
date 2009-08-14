require 'test_helper'

class UriMetaTest < Test::Unit::TestCase
  context 'URI.parse(http://www.metauri.com/)' do
    context '.meta' do
      setup do
        @uri = URI.parse('http://www.metauri.com/')
      end

      should 'exist' do
        @uri.respond_to? :meta
      end

      should 'be a URI::Meta object' do
        assert_kind_of URI::Meta, @uri.meta
      end

      context '.uri' do
        should 'be a URI object' do
          assert_kind_of URI, @uri.meta.uri
        end

        should 'not have been a redirect' do
          assert_equal @uri.to_s, @uri.meta.uri.to_s
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
      context '.uri' do
        should 'be a redirect' do
          assert_not_equal @uri.to_s, @uri.meta.uri.to_s
        end
      end
    end
  end

  context 'URI.parse(garbage).meta' do
    should 'raise errors' do
      assert_raise ArgumentError do
        URI.parse('garbage').meta
      end
    end
  end
end
