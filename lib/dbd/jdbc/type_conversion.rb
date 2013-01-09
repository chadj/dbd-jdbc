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

module DBI::DBD::Jdbc::TypeConversions
  java_import 'java.util.Calendar'
  java_import 'java.sql.Types'

  def jdbc_to_dbi_sqltype(jdbctype)
    return case jdbctype
    when Types::BIGINT then [DBI::SQL_BIGINT, nil]
    when Types::BINARY then [DBI::SQL_BINARY, nil]
    when Types::BIT then [DBI::SQL_BIT, DBI::Type::Boolean]
    when Types::CHAR then [DBI::SQL_CHAR, nil]
    when Types::DATE then [DBI::SQL_DATE, DBI::DBD::Jdbc::Type::Timestamp]
    when Types::DECIMAL then [DBI::SQL_DECIMAL, nil]
    when Types::DOUBLE then [DBI::SQL_DOUBLE, nil]
    when Types::FLOAT then [DBI::SQL_FLOAT, nil]
    when Types::INTEGER then [DBI::SQL_INTEGER, nil]
    when Types::LONGVARBINARY then [DBI::SQL_LONGVARBINARY, nil]
    when Types::LONGVARCHAR then [DBI::SQL_LONGVARCHAR, nil]
    when Types::NUMERIC then [DBI::SQL_NUMERIC, nil]
    when Types::REAL then [DBI::SQL_REAL, nil]
    when Types::SMALLINT then [DBI::SQL_SMALLINT, nil]
    when Types::TIME then [DBI::SQL_TIME, DBI::DBD::Jdbc::Type::Timestamp]
    when Types::TIMESTAMP then [DBI::SQL_TIMESTAMP, DBI::DBD::Jdbc::Type::Timestamp]
    when Types::TINYINT then [DBI::SQL_TINYINT, nil]
    when Types::VARBINARY then [DBI::SQL_VARBINARY, nil]
    when Types::VARCHAR then [DBI::SQL_VARCHAR, nil]
    else
      [DBI::SQL_OTHER, nil]
    end
  end

  def date_to_jdbcdate(dbidate)
    cal = Calendar.getInstance()
    set_calendar_date_fields(dbidate, cal)
    return java.sql.Date.new(cal.getTime().getTime())
  end

  def time_to_jdbctime(dbitime)
    cal = Calendar.getInstance()
    set_calendar_date_fields(dbitime, cal)
    set_calendar_time_fields(dbitime, cal)
    return java.sql.Time.new(cal.getTime().getTime())
  end

  def timestamp_to_jdbctimestamp(dbitimestamp)
    cal = Calendar.getInstance()
    set_calendar_date_fields(dbitimestamp, cal)
    set_calendar_time_fields(dbitimestamp, cal)
    return java.sql.Timestamp.new(cal.getTime().getTime())
  end

  def jdbcdate_to_date(jdbcdate)
    return nil if jdbcdate.nil?
    cal = get_calendar(jdbcdate)
    return ::Date.new(cal.get(Calendar::YEAR), cal.get(Calendar::MONTH)+1, cal.get(Calendar::DAY_OF_MONTH))
  end

  def jdbctime_to_time(jdbctime)
    return nil if jdbctime.nil?
    cal = get_calendar(jdbctime)
    return ::Time.mktime(cal.get(Calendar::YEAR), cal.get(Calendar::MONTH)+1, cal.get(Calendar::DAY_OF_MONTH), cal.get(Calendar::HOUR_OF_DAY), cal.get(Calendar::MINUTE), cal.get(Calendar::SECOND), cal.get(Calendar::MILLISECOND) * 1000)
  end

  def jdbctimestamp_to_timestamp(jdbctimestamp)
    return nil if jdbctimestamp.nil?
    cal = get_calendar(jdbctimestamp)
    return ::DateTime.new(cal.get(Calendar::YEAR), cal.get(Calendar::MONTH)+1, cal.get(Calendar::DAY_OF_MONTH), cal.get(Calendar::HOUR_OF_DAY), cal.get(Calendar::MINUTE), cal.get(Calendar::SECOND))
  end

  private

  def set_calendar_date_fields(dbidate, cal)
    cal.set(Calendar::YEAR, dbidate.year) if dbidate.respond_to? :year
    cal.set(Calendar::MONTH, dbidate.month-1) if dbidate.respond_to? :month
    cal.set(Calendar::DAY_OF_MONTH, dbidate.day) if dbidate.respond_to? :day
  end

  def set_calendar_time_fields(dbitime, cal)
    cal.set(Calendar::HOUR_OF_DAY, dbitime.hour)
    cal.set(Calendar::MINUTE, dbitime.min)
    cal.set(Calendar::SECOND, dbitime.sec)

    if dbitime.respond_to? :strftime
      cal.set(Calendar::MILLISECOND, dbitime.strftime('%L').to_i)
    else
      cal.set(Calendar::MILLISECOND, 0)
    end
  end

  def get_calendar(jdbctype)
    cal = Calendar.getInstance()
    cal.setTime(java.util.Date.new(jdbctype.getTime()))
    return cal
  end

end
