# frozen_string_literal: true
require "test_helper"

class ThreadSafetyTest < Minitest::Test
  def setup
    MiniMime::Db.reset!
  end

  def teardown
    MiniMime::Db.reset!
  end

  def test_concurrent_initialization_returns_one_database
    ready = Queue.new
    start = Queue.new
    threads = 16.times.map do
      Thread.new do
        ready << true
        start.pop
        MiniMime::Db.db
      end
    end

    16.times { ready.pop }
    16.times { start << true }

    assert_equal 1, threads.map(&:value).map(&:object_id).uniq.length
  end

  def test_concurrent_lookups_are_safe
    extensions = %w[zip txt jpg csv unknown]
    threads = 16.times.map do
      Thread.new do
        200.times do |iteration|
          MiniMime.lookup_by_extension(extensions[iteration % extensions.length])
        end
      end
    end

    assert_equal [200], threads.map(&:value).uniq
  end

  def test_lookup_after_fork
    skip "fork is only available on CRuby Unix" unless RUBY_ENGINE == "ruby" && Process.respond_to?(:fork)

    MiniMime.lookup_by_extension("zip")
    reader, writer = IO.pipe
    pid = fork do
      reader.close
      writer.write(MiniMime.lookup_by_extension("txt").content_type)
      writer.close
      exit! 0
    end

    writer.close
    result = reader.read
    _, status = Process.wait2(pid)

    assert_predicate status, :success?
    assert_equal "text/plain", result
  ensure
    reader&.close
    writer&.close unless writer&.closed?
  end
end
