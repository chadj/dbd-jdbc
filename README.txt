RECENT CHANGES
==============
The dbd-jdbc project has recently moved to Github and can be found at the following url 
(http://github.com/chadj/dbd-jdbc). Please report any bugs found to the issue 
tracker on Github.

OVERVIEW
========
The Jdbc driver for DBI runs only under JRuby, using JRuby's Java integration to act 
as a thin wrapper around JDBC Connections obtained through DriverManager.  
Theoretically this driver can support any database that has JDBC support, although the 
behavior of certain aspects of the DBI API will differ slightly based on the 
implementation of the JDBC driver and the underlying database (see LIMITATIONS) 

INSTALLATION
============
Besides the ruby files being installed with DBI (in DBD/Jdbc), the JDBC driver classes 
must be added to the JRuby classpath.  One way to do this on UNIX machines is to 
place a JDBC driver jarfile in JRUBY_HOME/lib.  Another way is to set the CLASSPATH 
environment variable.  The jruby (or jruby.bat) script can also be modified to add to 
the classpath.  In the future there may be more dynamic ways to add jarfiles to the 
classpath as well; check with the JRuby documentation.

USAGE
=====
This driver is used like any standard DBI driver, by requiring 'dbi' and obtaining a 
connection through the DBI.connect method.  The DSN for the database should be "dbi:" 
followed by the standard Java database URL (jdbc:<subprotocol>:<subname>).  In 
addition, the attributes hash passed to the connect method must contain the key/value 
pair "driver" => <jdbc driver class name>.  For example (MySQL):

dbh = DBI.connect('dbi:jdbc:mysql://localhost:3306/test', 'anonymous', '', 
        { "driver" => "com.mysql.jdbc.Driver" } )

SUPPORTED ATTRIBUTES
====================
Besides the mandatory "driver" attribute that must be passed in the DBI connect method, 
there are additional attributes that can be passed to modify the behavior of the 
driver.  In addition to setting these attributes during the connect call, they can be 
set on a driver handle using []= (e.g. dbh["autocommit"] = true).  The currently 
supported attributes are:

1) autocommit:  sets the autoCommit status of the underlying JDBC Connection 
   (there is a 1-1 relationship between a DBI Database instance and a JDBC Connection)
2) nulltype: sets the java.sql.Types constant to use when binding nil to a Statement.  
   See LIMITATIONS

LIMITATIONS
===========
There are limitations to the JDBC driver that are largely based on incompatibilities 
between the DBI and JDBC APIs, and the differences in underlying JDBC driver 
implementations.  

1) Binding nil to statements is somewhat unreliable due to the fact that JDBC requires 
type information in PreparedStatement.setNull(int), but there is no type information 
associated with nil in ruby.  E.g., statements like DBI.select_all("select * from a, b, 
c where col1=? and col2=?", "a", nil) might run into problems.  One workaround is to 
hardcode NULL in the sql statement.  If executing multiple inserts and some values 
might be nil, the driver will call setNull with the type specified in the driver 
attribute "nulltype".  If the default fails with a given driver, try specifying 
different nulltypes such as "dbh['nulltype'] = java.sql.Types::NULL" or 
"dbh['nulltype'] = java.sql.Types::OTHER" to see if it will work.

2) Type conversion in result sets: Java to Ruby type conversion in results of queries 
is more limited than in JDBC, since DBI returns an entire row at a time, without type 
information specified (unlike JDBC ResultSet where getInt, getString, etc allow each 
column to be typed appropriately).  The driver attempts to convert each data type, 
relying mostly on getObject() and the JRuby type conversion system.  Due to the fact 
that JDBC drivers are not constrained to the exact Java types returned for each SQL 
type, it is possible for some conversion oddities to arise (e.g. returning Java 
BigDecimal which isn't converted by JRuby, leading to a Java BigDecimal rather than 
Ruby Fixnum/BigDecimal).

3) Type conversion in prepared statements: In addition to not being able to use type 
data when returning data, it isn't possible to specify type data directly when binding 
parameters either (when binding multiple parameters, DBI has ability to set type data, 
and when calling bind_param, this driver does not currently support type data in the 
attributes).  Most conversions should work without problem, but there is ambiguity in 
the Ruby Float type since it can be treated as float or double (or BigDecimal) in Java 
(and FLOAT, DOUBLE, REAL, NUMERIC, DECIMAL, etc in java.sql.Types).  setDouble() is 
used to try to retain the highest precision, but some problems have been seen (e.g. 
Sybase REAL works better with setFloat()).  When doing inserts or retrieval, be sure 
that the driver keeps the desired precision (the only workaround is to change the 
database column type to something that works better for doubles with the given JDBC 
driver and database)
