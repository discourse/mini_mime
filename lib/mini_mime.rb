require "mini_mime/version"
require "thread"

module MiniMime
  BINARY_ENCODINGS = %w(base64 8bit)

  # return true if this filename is known to have binary encoding
  #
  # puts MiniMime.binary?("file.gif") => true
  # puts MiniMime.binary?("file.txt") => false
  def self.binary?(filename)
    info = Db.lookup(filename)
    !!(info && BINARY_ENCODINGS.include?(info.encoding))
  end

  # return first matching content type for a file
  #
  # puts MiniMime.content_type("test.xml") => "application/xml"
  # puts MiniMime.content_type("test.gif") => "image/gif"
  def self.content_type(filename)
    info = Db.lookup(filename)
    info && info.content_type
  end

  class Info
    attr_accessor :extension, :content_type, :encoding
    def initialize(buffer)
      @extension,@content_type,@encoding = buffer.split(/\s+/).map!(&:freeze)
    end
  end

  class Db
    LOCK = Mutex.new
    def self.lookup(filename)
      extension = File.extname(filename)
      if extension
        extension.sub!(".", "")
        if extension.length > 0
          LOCK.synchronize do
            @db ||= new
            @db.lookup(extension)
          end
        else
          nil
        end
      end
    end

    def initialize
      @db_path ||= File.expand_path("../db/mime.db", __FILE__)
      @file ||= File.open(@db_path)
      @cache = {}
      @row_length = @file.readline.length
      @file_length = @file.size
      @rows = @file_length / @row_length
    end

    def lookup(extension)
      @cache.fetch(extension) do
        @cache[extension] = lookup_uncached(extension)
      end
    end

    #lifted from marcandre/backports
    def lookup_uncached(extension)
      from = 0
      to = @rows - 1
      result = nil

      while from <= to do
        midpoint = from + (to-from).div(2)
        current = resolve(midpoint)
        if current.extension > extension
          to = midpoint - 1
        elsif current.extension < extension
          from = midpoint + 1
        else
          result = current
          break
        end
      end
      result
    end

    def resolve(row)
      @file.seek(row*@row_length)
      Info.new(@file.readline)
    end
  end
end
