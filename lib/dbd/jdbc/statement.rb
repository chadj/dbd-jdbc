#  (C) 2009 Chad Johnson <chad.j.johnson@gmail.com>.
#  (C) 2008 Ola Bini <ola.bini@gmail.com>.
#  (C) 2006 Kristopher Schmidt <krisschmidt@optonline.net>.
#
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
#  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
#  THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module DBI::DBD::Jdbc
  #
  # Models the DBI::BaseStatement API to create DBI::StatementHandle objects.
  #
  class Statement < DBI::BaseStatement
    include TypeConversions

    def initialize(statement, nulltype, allow_scroll = false)
      @statement = statement
      @nulltype = nulltype
      @allow_scroll = allow_scroll
      @rows = nil
      @data = []
    end

    def bind_param(param, value, attribs)
      raise DBI::InterfaceError.new("Statement.bind_param only supports numeric placeholder numbers") unless param.is_a?(Fixnum)
      if value.nil?
        @statement.setNull(param, @nulltype)
      elsif value.is_a?(String)
        #
        # The syntax below appears to be the best way to ensure that
        # RubyStrings get converted to Java Strings correctly if it
        # contains UTF-8.
        #
        # java.lang.String.new() will assume the system default
        # encoding when converting the RubyString bytes ....
        #
        @statement.setString(param, java.lang.String.new(value))
      elsif value.is_a?(Fixnum)
        #no reason not to coerce it to a long?
        @statement.setLong(param, value)
      elsif value.is_a?(Float)
        #despite DBD spec saying Float->SQL Float, using Double gives
        #better precision and passes tests that setFloat does not.
        @statement.setDouble(param, value)
      elsif value.is_a?(::DateTime) || value.is_a?(DBI::Timestamp)
        @statement.setTimestamp(param, timestamp_to_jdbctimestamp(value))
      elsif value.is_a?(::Date) || value.is_a?(DBI::Date)
        @statement.setDate(param, date_to_jdbcdate(value))
      elsif value.is_a?(::Time) || value.is_a?(DBI::Time)
        @statement.setTime(param, time_to_jdbctime(value))
      else
        @statement.setObject(param, value)
      end
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

    def execute
      if @statement.execute()
        @rs = @statement.getResultSet
        @rows = nil
        @data.clear
      else
        @rs = nil
        @rows = @statement.getUpdateCount
      end
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

    def finish
      @statement.close()
      @rs = nil
      @rows = nil
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

    def fetch
      if (@rs && @rs.next())
        return fill_data
      else
        return nil
      end
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

    def fill_data
      @data.clear
      metaData = @rs.getMetaData()
      (1..metaData.getColumnCount()).each do |columnNumber|
        @data << get_value(columnNumber, @rs, metaData)
      end
      return @data
    end

    #
    # Unless "allow_scroll" was set on this connection this will default to the
    # DBI::BaseStatement#fetch_scroll implementation.
    #
    # See DBI::BaseStatement#fetch_scroll. These additional constants are supported
    # when "allow_scroll" is set on the connection.
    #
    # * DBI::SQL_FETCH_PRIOR: Fetch the row previous to the current one.
    # * DBI::SQL_FETCH_FIRST: Fetch the first row.
    # * DBI::SQL_FETCH_ABSOLUTE: Fetch the row at the offset provided.
    # * DBI::SQL_FETCH_RELATIVE: Fetch the row at the current point + offset.
    #
    def fetch_scroll(direction, offset)
      return super(direction, offset) unless @allow_scroll

      case direction
      when DBI::SQL_FETCH_NEXT
        fill_data if @rs && @rs.next()
      when DBI::SQL_FETCH_PRIOR
        fill_data if @rs && @rs.previous()
      when DBI::SQL_FETCH_FIRST
        fill_data if @rs && @rs.first()
      when DBI::SQL_FETCH_LAST
        fill_data if @rs && @rs.last()
      when DBI::SQL_FETCH_ABSOLUTE
        fill_data if @rs && @rs.absolute(offset)
      when DBI::SQL_FETCH_RELATIVE
        fill_data if @rs && @rs.relative(offset)
      else
        raise DBI::NotSupportedError
      end
    rescue NativeException => error
      raise DBI::NotSupportedError.new(error.message)
    end

    def column_info
      info = Array.new
      return info unless @rs
      metaData = @rs.getMetaData()
      (1..metaData.getColumnCount()).each do |columnNumber|
        type_name, dbi_type = jdbc_to_dbi_sqltype(metaData.getColumnType(columnNumber))
        info << {
          "name" => metaData.getColumnName(columnNumber),
          "sql_type" => type_name,
          "type_name" => metaData.getColumnTypeName(columnNumber),
          "precision" => metaData.getPrecision(columnNumber),
          "scale" => metaData.getScale(columnNumber),
          "nullable" => (metaData.isNullable(columnNumber) == 1)
        }
        info[-1]["dbi_type"] = dbi_type if dbi_type
      end
      return info
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

    def rows
      return @rows
    end

    def self.from_java_statement(java_statement, type_coercion = false, null_type = java.sql.Types::VARCHAR)
      raise DBI::DatabaseError.new("Only java.sql.PreparedStatement instances accepted") unless java_statement.kind_of?(java.sql.PreparedStatement)

      DBI::StatementHandle.new(Statement.new(java_statement, null_type), true, true, type_coercion)
    end

    private

    def get_value(columnNumber, rs, metaData)
      #note only map things that seem unlikely to coerce properly to jruby,
      #since anything mapped as primitive type cannot be returned as null
      return case metaData.getColumnType(columnNumber)
      when java.sql.Types::BIT
        rs.getBoolean(columnNumber)
      when java.sql.Types::NUMERIC, java.sql.Types::DECIMAL
        # TODO: Find a better way to return Numerics and Decimals as nil when they are null in the DB
        if rs.getObject(columnNumber)
            metaData.getScale(columnNumber) == 0 ? rs.getLong(columnNumber) : rs.getDouble(columnNumber)
        else
            nil
        end
      when java.sql.Types::DATE
        jdbcdate_to_date(rs.getDate(columnNumber))
      when java.sql.Types::TIME
        jdbctime_to_time(rs.getTime(columnNumber))
      when java.sql.Types::TIMESTAMP
        jdbctimestamp_to_timestamp(rs.getTimestamp(columnNumber))
      else
        rs.getObject(columnNumber)
      end
    end

  end # class Statement

end # module Jdbc
