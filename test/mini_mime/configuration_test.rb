# frozen_string_literal: true
require 'test_helper'

class MiniMime::ConfigurationTest < Minitest::Test
  CUSTOM_EXT_MIME_DB_PATH = File.expand_path("../../fixtures/custom_ext_mime.db", __FILE__)
  CUSTOM_CONTENT_TYPE_MIME_DB_PATH = File.expand_path("../../fixtures/custom_content_type_mime.db", __FILE__)

  def setup
    MiniMime::Db.instance_variable_set(:@db, nil)
    @old_ext_db_path = MiniMime::Configuration.ext_db_path
    @old_content_type_db_path = MiniMime::Configuration.content_type_db_path
  end

  def teardown
    MiniMime::Db.instance_variable_set(:@db, nil)
    MiniMime::Configuration.ext_db_path = @old_ext_db_path
    MiniMime::Configuration.content_type_db_path = @old_content_type_db_path
  end

  def test_using_custom_ext_mime_db
    MiniMime::Configuration.ext_db_path = CUSTOM_EXT_MIME_DB_PATH

    assert_equal "application/x-lua", MiniMime.lookup_by_extension("lua").content_type
    assert_equal "quoted-printable", MiniMime.lookup_by_extension("m4v").encoding
  end

  def test_using_custom_content_type_mime_db
    MiniMime::Configuration.content_type_db_path = CUSTOM_CONTENT_TYPE_MIME_DB_PATH

    assert_equal "liquid", MiniMime.lookup_by_content_type("application/x-liquid").extension
    assert_equal "quoted-printable", MiniMime.lookup_by_content_type("video/vnd.objectvideo").encoding
  end
end
