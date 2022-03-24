# frozen_string_literal: true

require_relative "bgzfrb/version"
require 'zlib'
require 'stringio'

module Bgzfrb

  class Error < StandardError; end
  class Reader
    def self.open(fname)
      r = new(fname)
      r.each_block do |b|
        f = StringIO.new(b)
        yield f
      end
    end

    def initialize(fname)
      @f = File.open(fname, "rb")
    end

    def each_block
      until @f.eof?
        header = parse_header
        validate_header(header)
        extra = parse_extra(header)
        validate_extra(extra)
        cdata_size = extra[:BSIZE] - header[:XLEN] - 19
        cdata = @f.read(cdata_size)
        z = Zlib::Inflate.new(-15)
        buf = z.inflate(cdata)
        buf.force_encoding("ASCII")
        crc, isize = @f.read(8).unpack("LL")
        validate_cdata(buf, crc, isize)
        yield buf if buf.size > 0
      end
      @f.close
      validate_eof_maker(header, extra, crc, isize)
    end

    private

    def parse_header
      buf = @f.read(12)
      h = buf.unpack("CCCCLCCS")
      return {
        ID1: h[0],
        ID2: h[1],
        CM: h[2],
        FLG: h[3],
        MTIME: h[4],
        XFL: h[5],
        OS: h[6],
        XLEN: h[7],
      }
    end

    def parse_extra(header)
      buf = @f.read(header[:XLEN])
      extra = buf.unpack("CCSS")
      return {
        Sl1: extra[0],
        Sl2: extra[1],
        SLEN: extra[2],
        BSIZE: extra[3],
      }
    end

    def validate_header(header)
      if !(header[:ID1] == 31 &&
        header[:ID2] == 139 &&
        header[:CM] == 8 &&
        header[:FLG] == 4)
        raise "unsupported header: #{header}"
      end
    end

    def validate_extra(extra)
      if !(extra[:Sl1] == 66 &&
          extra[:Sl2] == 67 &&
          extra[:SLEN] == 2)
        raise "unsupported extra subfield: #{extra}"
      end
    end

    def validate_cdata(inflated, crc, isize)
      cmp_crc = Zlib::crc32(inflated, 0)
      if !(cmp_crc == crc && inflated.size == isize)
        raise "inflate error: #{crc} != #{cmp_crc}, #{inflated.size} != #{isize}"
      end
    end

    def validate_eof_maker(header, extra, crc, isize)
      header_maker = {:ID1=>31, :ID2=>139, :CM=>8, :FLG=>4, :MTIME=>0, :XFL=>0, :OS=>255, :XLEN=>6}
      extra_maker = {:Sl1=>66, :Sl2=>67, :SLEN=>2, :BSIZE=>27}
      crc_maker = 0
      isize_maker = 0

      if !(header == header_maker &&
          extra == extra_maker &&
          crc == crc_maker &&
          isize == isize_maker)
        raise "broken EOF maker"
      end
    end
  end
end
