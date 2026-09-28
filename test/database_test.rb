# frozen_string_literal: true
require "fileutils"
require "mime/types"
require "tempfile"
require "tmpdir"
require "test_helper"

# Rakefiles do not have a .rb extension, so require_relative cannot load this.
# rubocop:disable Discourse/Plugins/UseRequireRelative
load File.expand_path("../Rakefile", __dir__)
# rubocop:enable Discourse/Plugins/UseRequireRelative

class DatabaseTest < Minitest::Test
  def test_bundled_databases_have_fixed_byte_width_rows
    %w[content_type_mime.db ext_mime.db].each do |filename|
      path = File.expand_path("../lib/db/#{filename}", __dir__)
      widths = File.binread(path).lines.map(&:bytesize).uniq

      assert_equal 1, widths.length, "#{filename} contains rows with different byte widths"
    end
  end

  def test_random_access_database_uses_byte_offsets
    path = File.expand_path("fixtures/unicode_ext_mime.db", __dir__)
    database = MiniMime::Db::RandomAccessDb.new(path, 0)
    info = database.lookup("ê")

    refute_nil info
    assert_equal "text/two", info.content_type
  ensure
    database&.close
  end

  def test_random_access_database_search_boundaries
    with_database("a text/a 7bit\nm text/m 7bit\nz text/z 7bit\n") do |database|
      assert_equal "text/a", database.lookup("a").content_type
      assert_equal "text/m", database.lookup("m").content_type
      assert_equal "text/z", database.lookup("z").content_type

      assert_nil database.lookup("0")
      assert_nil database.lookup("b")
      assert_nil database.lookup("n")
      assert_nil database.lookup("zz")
    end
  end

  def test_reads_an_io_source_into_memory
    source = StringIO.new("a text/a 7bit\nz text/z 7bit\n")
    database = MiniMime::Db::RandomAccessDb.new(source, 0)

    assert_instance_of MiniMime::Db::MemoryFile, database_file(database)
    assert_equal "text/a", database.lookup("a").content_type
    assert_equal "text/z", database.lookup("z").content_type
  ensure
    database&.close
  end

  def test_reads_an_io_source_that_was_already_consumed
    source = StringIO.new("a text/a 7bit\n")
    source.read

    database = MiniMime::Db::RandomAccessDb.new(source, 0)

    assert_equal "text/a", database.lookup("a").content_type
  ensure
    database&.close
  end

  def test_falls_back_to_memory_for_a_path_that_is_not_a_file
    with_ftype("unknown") do
      with_database("a text/a 7bit\nz text/z 7bit\n") do |database|
        assert_instance_of MiniMime::Db::MemoryFile, database_file(database)
        assert_equal "text/a", database.lookup("a").content_type
        assert_equal "text/z", database.lookup("z").content_type
      end
    end
  end

  def test_uses_the_file_backend_for_a_plain_path
    with_database("a text/a 7bit\n") do |database|
      assert_instance_of MiniMime::Db::PReadFile, database_file(database)
    end
  end

  def test_rejects_an_empty_database
    assert_invalid_database("")
  end

  def test_rejects_rows_with_different_byte_widths
    assert_invalid_database("a text/a 7bit\nbb text/b 7bit\n")
  end

  def test_rejects_a_database_without_a_final_newline
    assert_invalid_database("a text/a 7bit")
  end

  def test_rejects_malformed_rows
    with_database("a text/a\n") do |database|
      assert_raises(ArgumentError) { database.lookup("a") }
    end
  end

  def test_rejects_invalid_utf8
    with_database("\xFF text/a 7bit\n".b) do |database|
      assert_raises(ArgumentError) { database.lookup("a") }
    end
  end

  def test_generator_pads_columns_to_equal_byte_widths
    rows = [["é".dup, "text/one".dup, "7bit".dup], ["abc".dup, "text/two".dup, "7bit".dup]]

    pad(rows)

    assert_equal 1, rows.map { |row| row.join(" ").bytesize }.uniq.length
  end

  def test_rebuild_uses_the_selected_types_preferred_extension
    expected_extensions = selected_preferred_extensions

    Dir.mktmpdir do |directory|
      FileUtils.mkdir_p(File.join(directory, "lib/db"))

      # rubocop:disable Discourse/NoChdir
      Dir.chdir(directory) do
        capture_io do
          Rake::Task[:rebuild_db].reenable
          Rake::Task[:rebuild_db].invoke
        end
      end
      # rubocop:enable Discourse/NoChdir

      generated = File.readlines(
        File.join(directory, "lib/db/content_type_mime.db"),
        chomp: true,
      ).to_h do |line|
        extension, content_type, = line.split
        [content_type, extension]
      end

      assert_equal expected_extensions, generated
      assert_equal "txt", generated.fetch("text/plain")
      assert_equal "jpeg", generated.fetch("image/jpeg")
      assert_equal "zip", generated.fetch("application/zip")
    end
  end

  private

  # JRuby reports "unknown" for a path inside an archive, a real file is always "file"
  def with_ftype(ftype)
    original = File.singleton_class.instance_method(:ftype)
    File.singleton_class.define_method(:ftype) { |*| ftype }
    yield
  ensure
    File.singleton_class.define_method(:ftype, original)
  end

  def database_file(database)
    database.instance_variable_get(:@file)
  end

  def assert_invalid_database(contents)
    Tempfile.create do |file|
      file.binmode
      file.write(contents)
      file.flush

      assert_raises(ArgumentError) { MiniMime::Db::RandomAccessDb.new(file.path, 0) }
    end
  end

  def with_database(contents)
    Tempfile.create do |file|
      file.binmode
      file.write(contents)
      file.flush

      database = MiniMime::Db::RandomAccessDb.new(file.path, 0)
      yield database
    ensure
      database&.close
    end
  end

  def selected_preferred_extensions
    types_by_extension = Hash.new { |hash, extension| hash[extension] = [] }
    MIME::Types.each do |type|
      type.extensions.each { |extension| types_by_extension[extension.downcase] << type }
    end

    types_by_extension.each do |extension, types|
      types.sort! { |left, right| left.__extension_priority_compare(right, [extension]) }
    end

    types_by_extension.each_value.with_object({}) do |types, preferred|
      selected = types.detect { |type| !type.obsolete? }
      selected ||= types.detect(&:registered)
      selected ||= types.first
      preferred[selected.content_type] ||= selected.preferred_extension
    end
  end
end
