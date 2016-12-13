require 'test_helper'
require 'mime/types/columnar'

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
    # note this is not strictly correct but .Z is the only
    # upper case extension, being correct here seems overkill
    assert MiniMime.binary?("a.z")
    assert MiniMime.binary?("a.Z")
    refute MiniMime.binary?("a.txt")
    refute MiniMime.binary?("a.frog")
  end

  def test_binary_content_type
    assert MiniMime.binary_content_type?("application/x-compress")
    refute MiniMime.binary_content_type?("something-fake")
    refute MiniMime.binary_content_type?("text/plain")
  end

  def test_full_parity_with_mime_types
    exts = Set.new
    MIME::Types.each do |type|
      type.extensions.each{|ext| exts << ext}
    end

    exts.each do |ext|
      type = MIME::Types.type_for("a.#{ext}").first
      assert_equal type.content_type, MiniMime.content_type("a.#{ext}")
    end
  end
end
