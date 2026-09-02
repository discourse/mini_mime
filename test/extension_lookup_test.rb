# frozen_string_literal: true
require "test_helper"

class ExtensionLookupTest < Minitest::Test
  class LookupCounter
    attr_reader :lookups

    def initialize(results = {})
      @results = results
      @lookups = []
    end

    def lookup_by_extension(extension)
      @lookups << extension
      @results[extension]
    end
  end

  def test_lowercase_miss_only_looks_up_once
    database = LookupCounter.new

    with_database(database) do
      assert_nil MiniMime.lookup_by_extension("unknown")
    end

    assert_equal ["unknown"], database.lookups
  end

  def test_mixed_case_miss_tries_the_lowercase_extension
    database = LookupCounter.new

    with_database(database) do
      assert_nil MiniMime.lookup_by_extension("Unknown")
    end

    assert_equal ["Unknown", "unknown"], database.lookups
  end

  def test_exact_case_hit_does_not_fall_back
    result = Object.new
    database = LookupCounter.new("ZiP" => result)

    with_database(database) do
      assert_same result, MiniMime.lookup_by_extension("ZiP")
    end

    assert_equal ["ZiP"], database.lookups
  end

  private

  def with_database(database)
    original_database = MiniMime::Db.instance_variable_get(:@db)
    MiniMime::Db.instance_variable_set(:@db, database)
    yield
  ensure
    MiniMime::Db.instance_variable_set(:@db, original_database)
  end
end
