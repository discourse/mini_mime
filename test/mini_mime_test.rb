# frozen_string_literal: true
require 'test_helper'

begin
  require 'mime/types/columnar'
rescue LoadError
end

class MiniMimeTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MiniMime::VERSION
  end

  def test_extension
    assert_equal "application/zip", MiniMime.lookup_by_extension("zip").content_type
  end

  def test_mixed_case

    # irb(main):009:0> MIME::Types.type_for("TxT").first.to_s
    # => "text/plain"

    assert_equal "application/vnd.groove-tool-message", MiniMime.lookup_by_filename("a.GTM").content_type
    assert_equal "application/zip", MiniMime.lookup_by_extension("ZiP").content_type
  end

  def test_content_type
    assert_equal "application/vnd.lotus-1-2-3", MiniMime.lookup_by_filename("a.123").content_type
    assert_equal "application/x-compressed", MiniMime.lookup_by_filename("a.Z").content_type
    assert_equal "application/vnd.groove-tool-message", MiniMime.lookup_by_filename("a.gtm").content_type
    assert_equal "application/vnd.HandHeld-Entertainment+xml", MiniMime.lookup_by_filename("a.zmm").content_type
    assert_equal "text/csv", MiniMime.lookup_by_filename("x.csv").content_type
    assert_equal "application/x-msaccess", MiniMime.lookup_by_filename("x.mda").content_type

    assert_nil MiniMime.lookup_by_filename("a.frog")
  end

  def test_binary
    # note this is not strictly correct but .Z is the only
    # upper case extension, being correct here seems overkill
    # many already rely on case insensitive lookups (which is implemented by mime types)
    assert MiniMime.lookup_by_filename("a.z").binary?
    assert MiniMime.lookup_by_filename("a.Z").binary?
    refute MiniMime.lookup_by_filename("a.txt").binary?
    assert_nil MiniMime.lookup_by_filename("a.frog")
  end

  def test_binary_content_type
    assert MiniMime.lookup_by_content_type("application/x-compressed").binary?
    assert_nil MiniMime.lookup_by_content_type("something-fake")
    refute MiniMime.lookup_by_content_type("text/plain").binary?
  end

  def should_prioritize_extensions_correctly
    assert_equal MiniMime.lookup_by_content_type("text/plain").extension, "txt"
  end

  if defined? MIME::Types
    WINDOWS_TYPES = {
      "cu" => "application/cu-seeme",
      "ecma" => "application/ecmascript",
      "es" => "application/ecmascript",
      "jar" => "application/java-archive",
      "ser" => "application/java-serialized-object",
      "mp4" => "application/mp4",
      "mpg4" => "application/mp4",
      "doc" => "application/msword",
      "pgp" => "application/octet-stream",
      "gpg" => "application/octet-stream",
      "ai" => "application/pdf",
      "asc" => "application/pgp-signature",
      "rtf" => "application/rtf",
      "spp" => "application/scvp-vp-response",
      "sgml" => "application/sgml",
      "curl" => "application/vnd.curl",
      "odc" => "application/vnd.oasis.opendocument.chart",
      "odf" => "application/vnd.oasis.opendocument.formula",
      "odi" => "application/vnd.oasis.opendocument.image",
      "bdm" => "application/vnd.syncml.dm+wbxml",
      "dcr" => "application/x-director",
      "exe" => "application/x-ms-dos-executable",
      "wmz" => "application/x-ms-wmz",
      "cmd" => "application/x-msdos-program",
      "bat" => "application/x-msdos-program",
      "com" => "application/x-msdos-program",
      "reg" => "application/x-msdos-program",
      "ps1" => "application/x-msdos-program",
      "vbs" => "application/x-msdos-program",
      "pm" => "application/x-pagemaker",
      "xml" => "application/xml",
      "dtd" => "application/xml-dtd",
      "kar" => "audio/midi",
      "mid" => "audio/midi",
      "midi" => "audio/midi",
      "m4a" => "audio/mp4",
      "mp2" => "audio/mpeg",
      "ogg" => "audio/ogg",
      "wav" => "audio/wav",
      "webm" => "audio/webm",
      "wmv" => "audio/x-ms-wmv",
      "ra" => "audio/x-pn-realaudio",
      "hif" => "image/heic",
      "sub" => "image/vnd.dvb.subtitle",
      "xbm" => "image/x-xbitmap",
      "mts" => "model/vnd.mts",
      "rst" => "text/plain",
    }

    def test_full_parity_with_mime_types
      exts = Set.new
      MIME::Types.each do |type|
        type.extensions.each { |ext| exts << ext }
      end

      differences = []

      exts.each do |ext|
        types = MIME::Types.type_for("a.#{ext}")

        type = types.detect { |t| !t.obsolete? }
        type ||= types.detect(&:registered)
        type ||= types.first

        # if type.content_type != MiniMime.lookup_by_filename("a.#{ext}").content_type
        #   puts "#{ext} Expected #{type.content_type} Got #{MiniMime.lookup_by_filename("a.#{ext}").content_type}"
        # end

        expected = type.content_type
        if WINDOWS_TYPES.key?(ext) && RUBY_PLATFORM.match?(/mingw|windows/i)
          expected = WINDOWS_TYPES[ext]
        end
        actual = MiniMime.lookup_by_filename("a.#{ext}").content_type

        if expected != actual
          differences << %{Expected ".#{ext}" to return #{expected.inspect}, got: #{actual.inspect}}
        end
      end

      assert differences.empty?, differences.join("\n")
    end
  end
end
