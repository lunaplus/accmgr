# encoding: utf-8
# Statistics model (統計)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'
require_relative './Expenditure'

=begin
create table statistics (
       iyear int,
       imonth int,
       owner varchar(9),
       AID varchar(20),
       EID varchar(20),
       amount bigint,
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
        datefrom = HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, m, 1))
        dateto = HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, m, -1))
        subquery = <<-SQL
          select s.EID, s.wdf, a1.name as wdfname,
                 a1.UID as wdfowner,
                 s.pmt, a2.name as pmtname, a2.UID as pmtowner, s.amt
            from (select EID, withdrawFrom as wdf, paymentTo as pmt,
                         sum(amount) as amt
                    from specifications
                   where wpdate between '#{datefrom}' and '#{dateto}'
                   group by EID, withdrawFrom, paymentTo) s
                 left join accounts a1 on a1.AID=s.wdf
                 left join accounts a2 on a2.AID=s.pmt
        SQL
        if owner != ALLOWNERS and aid == ALLACC
          # 所有者指定あり、口座指定なし
          #  収入計
          #    1.paymentTo(pmt)のownerが対象者かつ
          #      withdrawFrom(wdf)がnull
          #    2.pmt,wdfがいずれもnot nullかつ、
          #      pmtのownerが対象者、かつwdfのownerが対象者でない。
          #  支出計
          #    1.wdfのownerが対象者かつかつpmtがnull
          #    2.pmt,wdfがいずれもnot nullかつ、
          #      wdfのownerが対象者、かつpmtのownerが対象者でない。
          cond = <<-COND
            where (a1.uid = '#{owner}' and pmt is null)
               or (wdf is null and a2.uid = '#{owner}')
               or (wdf <> pmt and
                   (a1.uid = '#{owner}' or a2.uid = '#{owner}'))
          COND
          wfcond = " where wdfowner = '#{owner}' "
          pmcond = " where pmtowner = '#{owner}' "
          wfsel = " wdfowner as owner, '#{ALLACC}' as account, EID as exp, "
          pmsel = " pmtowner as owner, '#{ALLACC}' as account, EID as exp, "
        elsif owner != ALLOWNERS and aid != ALLACC
          # 所有者指定あり、口座指定あり
          #  収入計
          #    pmtが指定口座かつpmtのownerが対象者
          #  支出計
          #    wdfが指定口座かつwdfのownerが対象者
          cond = <<-COND
            where (wdf = '#{aid}' and a1.UID = '#{owner}')
               or (pmt = '#{aid}' and a2.UID = '#{owner}')
          COND
          wfcond = " where wdfowner = '#{owner}' and wdf = '#{aid}' "
          pmcond = " where pmtowner = '#{owner}' and pmt = '#{aid}' "
          wfsel = " wdfowner as owner, wdf as account, EID as exp, "
          pmsel = " pmtowner as owner, pmt as account, EID as exp, "
        elsif owner == ALLOWNERS and aid == ALLACC
          # 所有者指定なし、口座指定なし
          #  収入計
          #    1.paymentTo(pmt)がnot nullかつwithdrawFrom(wdf)がnull
          #    2.pmt,wdfがいずれもnot null
          #      pmtのowner != wdfのowner
          #  支出計
          #    1.wdfがnot nullかつpmtがnull
          #    2.pmt,wdfがいずれもnot nullかつ、
          #      pmtのowner != wdfのowner
          cond = <<-COND
            where (wdf is not null and pmt is null)
               or (wdf is null and pmt is not null)
               or (a1.UID <> a2.UID)
          COND
          wfcond = " where wdf is not null "
          pmcond = " where pmt is not null "
          wfsel = " '#{ALLOWNERS}' as owner, '#{ALLACC}' as account, " + 
            " EID as exp, "
          pmsel = " '#{ALLOWNERS}' as owner, '#{ALLACC}' as account, " +
            " EID as exp, "
        elsif owner == ALLOWNERS and aid != ALLACC
          # 所有者指定なし、口座指定あり
          #  収入計
          #    pmtが指定口座
          #  支出計
          #    wdfが指定口座
          cond = <<-COND
            where wdf = '#{aid}' or pmt = '#{aid}'
          COND
          wfcond = " where wdf = '#{aid}' "
          pmcond = " where pmt = '#{aid}' "
          wfsel = " '#{ALLOWNERS}' as owner, wdf as account, EID as exp, "
          pmsel = " '#{ALLOWNERS}' as owner, pmt as account, EID as exp, "
        end
        
        queryStr = <<-SQL
          insert into statistics(iyear, imonth, owner, AID, EID, amount)
          select iyear, imonth, owner, account, exp, sum(amount) as amount
            from (select #{y} as iyear, #{m} as imonth,
                         #{wfsel}
                         amt as amount
                    from ( #{subquery + cond} ) u
                         #{wfcond}
                  union all
                  select #{y} as iyear, #{m} as imonth,
                         #{pmsel}
                         -amt as amount
                      from ( #{subquery + cond} ) u
                         #{pmcond}
                 ) t
           group by iyear, imonth, owner, account, exp
        SQL
        mysqlClient.query(queryStr)
        
        retval = (mysqlClient.affected_rows > 0)
      rescue Mysql2::Error => e
        reterr = [e.message]
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end
    
    return {:retval => retval, :err => reterr}
  end
  
  def self.updStatsAllEid y,m
    retval = false
    reterr = nil

    datefrom = HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, m, 1))
    dateto = HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, m, -1))
    subquery = <<-SQL
      select s.EID, s.wdf, a1.name as wdfname,
             a1.UID as wdfowner,
             s.pmt, a2.name as pmtname, a2.UID as pmtowner, s.amt
        from (select EID, withdrawFrom as wdf, paymentTo as pmt,
                     sum(amount) as amt
                from specifications
               where wpdate between '#{datefrom}' and '#{dateto}'
               group by EID, withdrawFrom, paymentTo) s
             left join accounts a1 on a1.AID=s.wdf
             left join accounts a2 on a2.AID=s.pmt
    SQL

    begin
      mysqlClient = getMysqlClient
      
      # delete old stats
      queryStr = <<-SQL
        delete from statistics
         where iyear = #{y.to_s} and imonth = #{m.to_s}
           and AID = '#{ALLACC}' and EID IN ('#{ALLEIDOUT}', '#{ALLEIDIN}')
      SQL
      mysqlClient.query(queryStr)

      # calc and insert ALLOUT Expenditures per owners
      queryStr = <<-SQL
      insert into statistics(iyear, imonth, owner, AID, EID, amount)
        select #{y} as iyear, #{m} as imonth,
               wdfowner as owner, '#{ALLACC}' as AID,
               '#{ALLEIDOUT}' as EID,
               sum(amt) as amount
          from ( #{subquery}
                 where (a1.UID <> a2.UID
                        or (a1.UID is not null
                            and a2.UID is null))
               ) u
         group by wdfowner
      SQL
      mysqlClient.query(queryStr)
      retval = (mysqlClient.affected_rows > 0)

      # calc and insert ALLIN Expenditures per owners
      queryStr = <<-SQL
        insert into statistics(iyear, imonth, owner, AID, EID, amount)
        select #{y} as iyear, #{m} as imonth,
               pmtowner as owner, '#{ALLACC}' as AID,
               '#{ALLEIDIN}' as EID,
               sum(-amt) as amount
          from ( #{subquery}
                 where (a1.UID <> a2.UID
                        or (a1.UID is null
                            and a2.UID is not null))
               ) u
         group by pmtowner
      SQL
      mysqlClient.query(queryStr)
      retval = (retval ? (mysqlClient.affected_rows > 0) : false)

      # calc and insert ALLOUT Expenditures
      queryStr = <<-SQL
      insert into statistics(iyear, imonth, owner, AID, EID, amount)
        select #{y} as iyear, #{m} as imonth,
               '#{ALLOWNERS}' as owner, '#{ALLACC}' as AID,
               '#{ALLEIDOUT}' as EID,
               sum(amt) as amount
          from ( #{subquery}
                 where (wdf is not null
                        and pmt is null)
               ) u
      SQL
      mysqlClient.query(queryStr)
      retval = (retval ? (mysqlClient.affected_rows > 0) : false)

      # calc and insert ALLIN Expenditures
      queryStr = <<-SQL
        insert into statistics(iyear, imonth, owner, AID, EID, amount)
        select #{y} as iyear, #{m} as imonth,
               '#{ALLOWNERS}' as owner, '#{ALLACC}' as AID,
               '#{ALLEIDIN}' as EID,
               sum(-amt) as amount
          from ( #{subquery}
                 where (wdf is null
                        and pmt is not null)
               ) u
      SQL
      mysqlClient.query(queryStr)
      retval = (retval ? (mysqlClient.affected_rows > 0) : false)

    rescue Mysql2::Error => e
      reterr = e.message
      retval = false
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end

    return {:retval => retval, :err => reterr}
  end
end
