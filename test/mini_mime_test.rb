require 'test_helper'

class MiniMimeTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MiniMime::VERSION
  end


  def test_content_type
    # keep lotus alive cause these files are EVERYWHERE
    assert_equal "application/vnd.lotus-1-2-3", MiniMime.content_type("a.123")
    assert_equal "application/x-compress", MiniMime.content_type("a.Z")
    assert_equal "application/vnd.groove-tool-message", MiniMime.content_type("a.gtm")
    assert_equal "application/vnd.HandHeld-Entertainment+xml", MiniMime.content_type("a.zmm")
    assert_nil MiniMime.content_type("a.frog")
  end

  def test_binary
    assert MiniMime.binary?("a.Z")
    refute MiniMime.binary?("a.txt")
    refute MiniMime.binary?("a.frog")
  end
end
