# encoding: utf-8
# Statistics model (統計)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'
require_relative './Expenditure'
require_relative './CgiUser'
require_relative './Account'

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
        (m < 1) or (13 < m)
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

  def self.updStatsSpecificEids y,m,owner,aid
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
        datefrom =
          HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, (m==13 ? 1 : m), 1))
        dateto =
          HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, (m==13 ? 12 : m), -1))
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
          wfsel2 = " wdfowner as owner, '#{ALLACC}' as account, " +
            " '#{ALLEIDOUT}' as exp, "
          pmsel2 = " pmtowner as owner, '#{ALLACC}' as account, " +
            " '#{ALLEIDIN}' as exp, "
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
          wfsel2 =
            " wdfowner as owner, wdf as account, '#{ALLEIDOUT}' as exp, "
          pmsel2 =
            " pmtowner as owner, pmt as account, '#{ALLEIDIN}' as exp, "
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
          wfsel2 = " '#{ALLOWNERS}' as owner, '#{ALLACC}' as account, " + 
            " '#{ALLEIDOUT}' as exp, "
          pmsel2 = " '#{ALLOWNERS}' as owner, '#{ALLACC}' as account, " +
            " '#{ALLEIDIN}' as exp, "
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
          wfsel2 =
            " '#{ALLOWNERS}' as owner, wdf as account, '#{ALLEIDOUT}' as exp, "
          pmsel2 =
            " '#{ALLOWNERS}' as owner, pmt as account, '#{ALLEIDIN}' as exp, "
        end
        
        queryStr = <<-SQL
          insert into statistics(iyear, imonth, owner, AID, EID, amount)
          select iyear, imonth, owner, account, exp, sum(amount) as amount
            from (select #{y} as iyear, #{m} as imonth,
                         #{wfsel}
                         -amt as amount
                    from ( #{subquery + cond} ) u
                         #{wfcond}
                  union all
                  select #{y} as iyear, #{m} as imonth,
                         #{pmsel}
                         amt as amount
                      from ( #{subquery + cond} ) u
                         #{pmcond}
                 ) t
           group by iyear, imonth, owner, account, exp
        SQL
        mysqlClient.query(queryStr)
        retval = (mysqlClient.affected_rows > 0)

        queryStr = <<-SQL
          insert into statistics(iyear, imonth, owner, AID, EID, amount)
          select iyear, imonth, owner, account, exp, amount
            from (select #{y} as iyear, #{m} as imonth,
                         #{wfsel2}
                         sum(-amt) as amount
                    from ( #{subquery + cond} ) u
                         #{wfcond}
                   group by iyear, imonth, owner, account
                  union all
                  select #{y} as iyear, #{m} as imonth,
                         #{pmsel2}
                         sum(amt) as amount
                    from ( #{subquery + cond} ) u
                         #{pmcond}
                   group by iyear, imonth, owner, account
                 ) t
        SQL
        mysqlClient.query(queryStr)

        retval = retval and (mysqlClient.affected_rows > 0)
      rescue Mysql2::Error => e
        reterr = [e.message]
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end
    
    return {:retval => retval, :err => reterr}
  end
  
  def self.updStatsAllEid y,m=13
    retval = false
    reterr = nil

    datefrom =
      HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, (m==13 ? 1 : m), 1))
    dateto =
      HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, (m==13 ? 12 : m), -1))
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
               sum(-amt) as amount
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
               sum(amt) as amount
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
               sum(-amt) as amount
          from ( #{subquery}
                 where (wdf is not null
                        and pmt is null)
               ) u
        having sum(amt) is not null
      SQL
      mysqlClient.query(queryStr)
      retval = (retval ? (mysqlClient.affected_rows > 0) : false)

      # calc and insert ALLIN Expenditures
      queryStr = <<-SQL
        insert into statistics(iyear, imonth, owner, AID, EID, amount)
        select #{y} as iyear, #{m} as imonth,
               '#{ALLOWNERS}' as owner, '#{ALLACC}' as AID,
               '#{ALLEIDIN}' as EID,
               sum(amt) as amount
          from ( #{subquery}
                 where (wdf is null
                        and pmt is not null)
               ) u
        having sum(amt) is not null
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
  private_class_method :chk
  private_class_method :updStatsSpecificEids
  private_class_method :updStatsAllEid

  def self.getStats y,m=13,uid=ALLOWNERS,aid=ALLACC
    retval = Array.new
    reterr = nil

    unless y.is_a?(Integer) or m.is_a?(Integer)
      reterr = "年月は整数で指定してください。"
    else
      begin
        mysqlClient = getMysqlClient
        queryStr = <<-SQL
          select s.iyear as y, s.imonth as m,
                 ifnull(u.Name, s.owner) as owner,
                 ifnull(a.name, s.AID) as aid,
                 ifnull(e.name, s.EID) as eid,
                 s.amount as amount
            from statistics s
                 left join accounts a on s.AID = cast(a.AID as char)
                 left join expenditures e on s.EID = cast(e.EID as char)
                 left join cgiUsers u on s.owner = u.UID
           where s.iyear = #{y.to_s} and s.imonth = #{m.to_s}
                 and s.owner = '#{uid}'
                 and s.AID='#{aid}'
           order by owner, aid, eid
        SQL
        rsltset = mysqlClient.query(queryStr)
        rsltset.each do |row|
          retval.push({ :y => row["y"],
                        :m => row["m"],
                        :owner => row["owner"],
                        :aid => row["aid"],
                        :eid => row["eid"],
                        :amount => row["amount"] })
        end
      rescue Mysql2::Error => e
        reterr = e.message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end

    return {:retval => retval, :err => reterr}
  end

  def self.updStats y,m=13
    retval = Array.new

    # upd specifc eid stats
    uids = CgiUser.getUserList
    aids = Account.list
    if uids[:iserr]==true
      retval.push(uids[:errstr])
    elsif (not aids[:err].nil?)
      retval.push(aids[:err])
    else
      uids = uids[:ulist].map{ |elm| elm[:uid] }.push(ALLOWNERS)
      aids = aids[:retval].map{ |elm| elm[:AID].to_s }.push(ALLACC)
      
      uids.each do |uid|
        aids.each do |aid|
          ret = updStatsSpecificEids y,m,uid,aid
          if (not ret[:retval]) and (not ret[:err].nil?)
            retval.concat(ret[:reterr])
          end
        end
      end
    end
    
    # upd all stats
    ret = updStatsAllEid y,m
    if (not ret[:retval]) and (not ret[:err].nil?)
      retval.push(ret[:err])
    end
    return { :retval => (retval.size==0), :err => retval }
  end
end
