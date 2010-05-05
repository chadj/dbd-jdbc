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
  # Models the DBI::BaseDriver API to create DBI::DriverHandle objects.
  #
  class Driver < DBI::BaseDriver

    def initialize
      super("0.4.0")
      #attributes specific to this class.  All attributes in the
      #connect attributes that aren't in this list will be
      #applied to the database handle
      @driverAttributes = [ "driver" ]
      @loaded_drivers = Collections.synchronizedMap(HashMap.new)
    end

    def load(name)
      unless @loaded_drivers.containsKey(name)
        clazz = java.lang.Class.forName(name,true,JRuby.runtime.jruby_class_loader)
        java.sql.DriverManager.registerDriver(clazz.newInstance)
        
        @loaded_drivers.put(name,true)
      end
    end

    def connect(dbname, user, auth, attr)
      driverClass = attr["driver"]
      raise DBI::InterfaceError.new('driver class name must be specified as "driver" in connection attributes') unless driverClass

      load(driverClass)

      connection = java.sql.DriverManager.getConnection("jdbc:"+dbname, user, auth)
      dbh = Database.new(connection)

      (attr.keys - @driverAttributes).each { |key| dbh[key] = attr[key] }

      return dbh
    rescue NativeException => error
      raise DBI::DatabaseError.new(error.message)
    end

  end #Driver
end