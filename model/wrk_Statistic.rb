# encoding: utf-8
# Statistics model (統計)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

=begin
create table statistics (
       iyear int,
       imonth int,
       owner varchar(9),
       AID varchar(20),
       EID varchar(20),
       amount bigint unsigned,
       primary key(iyear, imonth, owner, AID, EID)
);
-- owner : UID(8) + 'ALLOWNERS'
-- AID : (bigint).to_s + 'ALLACCOUNTS'
-- EID : (bigint).to_s + 'INALL','OUTALL'
-- max(bigint unsigned)=18446744073709551615 // len(max(bigint unsigned))=20
=end

class Statistic < ModelMaster
  ALLOWNERS = "ALLOWNERS"
  ALLACC = "ALLACCOUNTS"
  ALLEIDIN = "INALL"
  ALLEIDOUT = "OUTALL"

  def self.chk y,m,o,a
    reterr = Array.new

    # year
    if y.nil? or (not y.is_a?(Integer))
      reterr.push("年指定は数値で指定してください。")
    end
    # month
    if m.nil? or (not m.is_a?(Integer)) or
        (m < 1) or (12 < m)
      reterr.push("月指定が不正です。")
    end
    # owner
    if o.nil? or (not o.is_a?(String)) or
        ((o != ALLOWNERS) and ((o.length < 1) or (8 < o.length)))
      reterr.push("所有者指定が不正です。")
    end
    # aid
    if a.nil? or (not a.is_a?(String))
      reterr.push("口座指定が不正です。")
    end

    reterr = nil if reterr.size==0
    return reterr
  end

  def self.getStats y,m,owner,aid
    retval = Array.new
    reterr = nil

    chkrslt = chk(y,m,owner,aid)
    unless chkrslt.nil?
      reterr = chkrslt
    else
      begin
        mysqlClient = getMysqlClient
        
      rescue Mysql2::Error => e
        reterr = [e.message]
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end

    return {:retval => retval, :err => reterr}
  end

  def self.updStats y,m,owner,aid
    retval = false
    reterr = nil

    chkrslt = chk(y,m,owner,aid)
    unless chkrslt.nil?
      reterr = chkrslt
    else
      begin
        mysqlClient = getMysqlClient

        # delete old stats
        queryStr = <<-SQL
          delete from statistics
           where iyear = #{y.to_s} and imonth = #{m.to_s}
             and owner = '#{owner}' and AID = '#{aid}'
        SQL
        mysqlClient.query(queryStr)

        # calc and insert new stats
=begin
  ●口座指定ない場合
  収入計
    1.paymentTo(pmt)がnot nullかつwithdrawFrom(wdf)がnullかつ、
      pmtのownerが対象者。
    2.pmt,wdfがいずれもnot nullかつ、
      pmtのownerが対象者、かつwdfのownerが対象者でない。
  支出計
    1.wdfがnot nullかつpmtがnull
    2.pmt,wdfがいずれもnot nullかつ、
      wdfのownerが対象者、かつpmtのownerが対象者でない。

  ●口座指定ある場合
  収入計
    pmtが指定口座
  支出計
    wdfが指定口座

=end
        subquery = <<-SQL
          select s.EID, s.wdf, a1.name as wdfname,
                 a1.UID as wdfowner,
                 s.pmt, a2.name as pmtname, a2.UID as pmtowner, s.amt
            from (select EID, withdrawFrom as wdf, paymentTo as pmt,
                         sum(amount) as amt
                    from specifications
                   where wpdate between '2016-1-1' and '2016-1-31'
                   group by EID, withdrawFrom, paymentTo) s
            left join accounts a1 on s.wdf = a1.AID
            left join accounts a2 on s.pmt = a2.AID
        SQL

        if aid == ALLACC # 全口座を対象とする場合
          subquery += <<-COND
             where (a1.uid = '#{owner}' and a2.uid is null)
                or (a1.uid is null and a2.uid = '#{owner}')
                or (a1.uid <> a2.uid and
                    (a1.uid = '#{owner}' or a2.uid = '#{owner}'))
          COND
        else # 指定口座について集計する場合
          subquery += <<-COND
            where s.wdf = '#{aid}' or s.pmt = '#{aid}'
          COND
        end

        preStr = <<-SQL
          select #{y} as y, #{m} as m,
        SQL
        postStr = <<-SQL
                 EID, sum(amt) as amt
            from (#{subquery}) u
        SQL

        wdfstr = " wdf, wdfowner, "
        pmtstr = " pmt, pmtowner, "
        if aid == ALLACC
          wdfstr2 = " where wdfowner = '#{owner}' "
          pmtstr2 = " where pmtowner = '#{owner}' "
        else
          wdfstr2 = " where wdfowner = '#{owner}' and wdf = #{aid} "
          pmtstr2 = " where pmtowner = '#{owner}' and pmt = #{aid} "
        end
        wdfstr2 += " group by #{wdfstr} EID "
        pmtstr2 += " group by #{pmtstr} EID "

        queryStr = preStr + wdfstr + postStr + wdfstr2 +
          " union " + preStr + pmtstr + postStr + pmtstr2

        reterr = [queryStr]

        # retval = true
      rescue Mysql2::Error => e
        reterr = [e.message]
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end

    return {:retval => retval, :err => reterr}
  end
end
