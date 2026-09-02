# frozen_string_literal: true
require "test_helper"

class CacheTest < Minitest::Test
  class CountingRandomAccessDb < MiniMime::Db::RandomAccessDb
    attr_reader :uncached_lookups

    def initialize(...)
      @uncached_lookups = 0
      super
    end

    def lookup_uncached(value)
      @uncached_lookups += 1
      super
    end
  end

  def test_random_access_database_caches_hits_and_misses
    path = File.expand_path("fixtures/unicode_ext_mime.db", __dir__)
    database = CountingRandomAccessDb.new(path, 0)

    2.times { assert_equal "text/one", database.lookup("é").content_type }
    2.times { assert_nil database.lookup("unknown") }
    assert_equal 2, database.uncached_lookups
  ensure
    database&.close
  end

  def test_fetch_returns_a_cached_value_without_running_the_block
    cache = MiniMime::Db::Cache.new(2)
    cache[:key] = "cached"

    assert_equal "cached", cache.fetch(:key) { flunk "cache block should not run" }
  end

  def test_fetch_distinguishes_a_cached_nil_from_a_missing_key
    cache = MiniMime::Db::Cache.new(2)
    cache[:key] = nil

    assert_nil cache.fetch(:key) { flunk "cache block should not run" }
  end

  def test_evicts_the_oldest_entry_when_full
    cache = MiniMime::Db::Cache.new(2)
    cache[:first] = 1
    cache[:second] = 2
    cache[:third] = 3

    assert_equal :missing, cache.fetch(:first) { :missing }
    assert_equal 2, cache.fetch(:second) { flunk "second entry should be cached" }
    assert_equal 3, cache.fetch(:third) { flunk "third entry should be cached" }
  end

  def test_updating_an_entry_does_not_evict_another_entry
    cache = MiniMime::Db::Cache.new(2)
    cache[:first] = 1
    cache[:second] = 2
    cache[:first] = 3

    assert_equal 3, cache.fetch(:first) { flunk "first entry should be cached" }
    assert_equal 2, cache.fetch(:second) { flunk "second entry should be cached" }
  end
end
