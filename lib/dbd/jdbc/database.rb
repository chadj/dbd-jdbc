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
  # Models the DBI::BaseDatabase API to create DBI::DatabaseHandle objects.
  #
  class Database < DBI::BaseDatabase
    include TypeConversions

    def initialize(connection)
      @connection = connection
      @attributes = {
        #works with Sybase and Mysql.
        "nulltype" => java.sql.Types::VARCHAR,
        "allow_scroll" => false
      }
    end

    def disconnect
      @connection.rollback unless self["autocommit"]
      @connection.close
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

    def prepare(sql)
      if self["allow_scroll"]
        return Statement.new(@connection.prepareStatement(sql,ResultSet::TYPE_SCROLL_INSENSITIVE, ResultSet::CONCUR_READ_ONLY), self["nulltype"], self["allow_scroll"])
      else
        return Statement.new(@connection.prepareStatement(sql), self["nulltype"], self["allow_scroll"])
      end
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

    def do(statement, *bindvars)
        res = nil
        if bindvars.nil? || bindvars.empty?
          stmt = @connection.createStatement()
          begin
            stmt.execute(statement)
          ensure
            stmt.close rescue NativeException
          end
        else
          stmt = execute(statement, *bindvars)
          res = stmt.rows
          stmt.finish
        end
        return res
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def ping
        return !@connection.isClosed
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def commit
        @connection.commit()
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def rollback
        @connection.rollback()
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def tables
        rs = @connection.getMetaData.getTables(nil, nil, nil, nil)
        tables = []
        while(rs.next())
          tables << rs.getString(3)
        end
        return tables
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def columns(table)
        (table,schema,db) = table.split(".").reverse
          
        metaData = @connection.getMetaData()
        rs = metaData.getColumns(db, schema, table, nil)
        columns = []
        while(rs.next())
          type_name, dbi_type = jdbc_to_dbi_sqltype(rs.getShort(5))
          columns << {
            "name" => rs.getString(4),
            "sql_type" => type_name,
            "type_name" => rs.getString(6),
            "precision" => rs.getInt(7),
            "scale" => rs.getInt(9),
            "default" => rs.getString(13),
            "nullable" => (rs.getInt(11) == 1)
          }
          columns[-1]["dbi_type"] = dbi_type if dbi_type
        end
        return columns
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def [](attribute)
        attribute = attribute.downcase
        check_attribute(attribute)
        case attribute
        when "autocommit" then @connection.getAutoCommit()
        when "isolation", "isolation_level" then @connection.getTransactionIsolation()
        else
          @attributes[attribute]
        end
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def []=(attribute, value)
        attribute = attribute.downcase
        check_attribute(attribute)
        case attribute
        when "autocommit" then @connection.setAutoCommit(value)
        when "isolation", "isolation_level" then @connection.setTransactionIsolation(value)
        else
          @attributes[attribute] = value
        end
      rescue NativeException => error
        raise DBI::DatabaseError.new(error.message)
      end

      def java_connection
        return @connection
      end

      def self.from_java_connection(java_connection, type_coercion = true)
        dbh = DBI::DatabaseHandle.new(Database.new(java_connection), type_coercion)
        dbh.driver_name = "Jdbc"
        dbh
      end

      private

      def check_attribute(attribute)
          raise DBI::NotSupportedError.new("Database attribute #{attribute} is not supported") unless (attribute == "autocommit" ||
                                                                                                       attribute == "isolation" ||
                                                                                                       attribute == "isolation_level" ||
                                                                                                       @attributes.has_key?(attribute))
      end

    end
  end # module DBI
