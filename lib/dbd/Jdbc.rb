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

require 'java'

begin
  require 'rubygems'
  gem 'dbi'
rescue LoadError => e
end

require 'dbi'

module DBI
  module DBD
    #
    # DBD::Jdbc - Database Driver for Java / JDBC
    #
    # Requires DBI and JRuby
    #
    module Jdbc
      include_class 'java.sql.Connection'
      include_class 'java.sql.ResultSet'
      include_class 'java.util.HashMap'
      include_class 'java.util.Collections'

      VERSION = "0.1.5"
      DESCRIPTION = "JDBC DBD driver for JRuby"

      #
      # Transaction isolation levels copied from JDBC
      #
      TRANSACTION_NONE = Connection::TRANSACTION_NONE
      TRANSACTION_READ_COMMITTED = Connection::TRANSACTION_READ_COMMITTED
      TRANSACTION_READ_UNCOMMITTED = Connection::TRANSACTION_READ_UNCOMMITTED
      TRANSACTION_REPEATABLE_READ = Connection::TRANSACTION_REPEATABLE_READ
      TRANSACTION_SERIALIZABLE = Connection::TRANSACTION_SERIALIZABLE 
      # Convience isolation levels
      NONE = Connection::TRANSACTION_NONE
      READ_COMMITTED = Connection::TRANSACTION_READ_COMMITTED
      READ_UNCOMMITTED = Connection::TRANSACTION_READ_UNCOMMITTED
      REPEATABLE_READ = Connection::TRANSACTION_REPEATABLE_READ
      SERIALIZABLE = Connection::TRANSACTION_SERIALIZABLE        
        
      #
      # returns 'Jdbc'
      #
      # See DBI::TypeUtil#convert for more information.
      #
      def self.driver_name
        "Jdbc"
      end

      module Type
        class Timestamp < DBI::Type::Null
          def self.parse(obj)
            obj = super
            return obj unless obj

            if obj.kind_of?(::DateTime) || obj.kind_of?(::Time) || obj.kind_of?(::Date)
              return obj
            elsif obj.kind_of?(::String)
              return ::DateTime.strptime(obj, "%Y-%m-%d %H:%M:%S")
            else
              return ::DateTime.parse(obj.to_s)   if obj.respond_to? :to_s
              return ::DateTime.parse(obj.to_str) if obj.respond_to? :to_str
              return obj
            end
          end
        end
      end

      #
      # Bound values pass through this function before being handed to Statement.bind_param
      #
      # The false value prevents the default type conversion from occurring
      #
      DBI::TypeUtil.register_conversion(driver_name) do |obj|
        [obj, false]
      end
    end
  end
end

require 'dbd/jdbc/type_conversion'
require 'dbd/jdbc/driver'
require 'dbd/jdbc/database'
require 'dbd/jdbc/statement'
