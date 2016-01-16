# encoding: utf-8
# Specifications model (明細)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'
require_relative './Expenditure'
require_relative './Account'

=begin
create table specifications (
       SID bigint auto_increment primary key,
       wpdate datetime, -- withdraw or payment
       EID bigint,
       withdrawFrom bigint,
       paymentTo bigint,
       amount bigint,
       paymentMonth int
);
=end

class Specification < ModelMaster

  def self.chkSpc arg
    tmperr = Array.new

    if arg.has_key?(:wpd)
      wpd = arg[:wpd]
      if wpd.nil? or (not wpd.instance_of?(String)) or wpd.empty?
        # wpd must be input / as String
        tmperr.push("引出しまたは支払い日付は必須入力です。")
      elsif (HtmlUtil.fmtStrToDt wpd).nil?
        # wpd must formed HtmlUtil.REGxxFMT
        tmperr.push("引出しまたは支払い日付の書式を確認してください。")
      end
    end
    if arg.has_key?(:eid)
      eid = arg[:eid]
      if eid.nil? or (not eid.is_a?(Integer))
        # eid must be input / as Integer(super class of Fixnum,Bignum)
        tmperr.push("費目は必須入力です。")
      elsif not Expenditure.isExist?(eid)
        # eid must exist at Expenditures
        tmperr.push("登録されていない費目は指定できません。")
      end
    end
    if arg.has_key?(:wdFrom) or arg.has_key?(:pmTo)
      wdFrom = arg[:wdFrom]
      pmTo = arg[:pmTo]
      if wdFrom.nil? and pmTo.nil?
        # wdFrom or pmTo must be input
        tmperr.push("引落し口座または支払い口座の" +
                    "いずれか1つ以上入力してください。")
      else
        if (not wdFrom.nil?)
          if not Account.isExist?(wdFrom)
            # wdFrom as Integer / must exist at Accounts
            tmperr.push("登録されていない支払い元は指定できません。")
          end
        end
        if (not pmTo.nil?)
          if not Account.isExist?(pmTo)
            # pmTo as Integer / must exist at Accounts
            tmperr.push("登録されていない支払い先は指定できません。")
          end
        end
      end
    end
    if arg.has_key?(:amount)
      amount = arg[:amount]
      if amount.nil?
        # amount must be input
        tmperr.push("金額は必須入力です。")
      elsif not amount.is_a?(Integer)
        # amount as Integer
        tmperr.push("金額は整数で入力してください。")
      end
    end
    if arg.has_key?(:pmonth)
      pmonth = arg[:pmonth]
      if (not pmonth.nil?) and
          ( (not pmonth.is_a?(Integer)) or
            pmonth < 1 or 12 < pmonth )
        # pmonth as Integer
        tmperr.push("カード支払い月が不正です。")
      end
    end
    
    return tmperr
  end
  private_class_method :chkSpc

  def self.list(from=nil,to=nil)
    retval = Array.new
    reterr = nil

    # input check from, to
    frdt = (from.nil? ? "" : (HtmlUtil.fmtStrToDt from))
    todt = (to.nil? ? "" : (HtmlUtil.fmtStrToDt to))
    if frdt.nil? or todt.nil?
      reterr = ""
      reterr += "from書式が不正です。" if frdt.nil?
      reterr += "to書式が不正です。" if todt.nil?
    else
      begin
        queryStr = <<-SQL
          select SID, wpdate, EID, withdrawFrom, paymentTo,
                 amount, paymentMonth
            from specifications
        SQL
        # add condition of from, to
        if frdt != "" or todt != ""
          queryStr += " where "
          queryStr += " wpdate >= '" + (HtmlUtil.fmtDtToStr frdt) +
            "' " if frdt != ""
          queryStr += " and " if frdt!= "" and todt != ""
          queryStr += " wpdate <= '" + (HtmlUtil.fmtDtToStr todt) +
            "' " if todt != ""
        end
        queryStr += " order by wpdate "
        mysqlClient = getMysqlClient
        rsltSet = mysqlClient.query(queryStr)
        
        rsltSet.each do |row|
          retval.push({ :SID => row["SID"],
                        :wpdate => row["wpdate"],
                        :EID => row["EID"],
                        :wFrom => row["withdrawFrom"],
                        :pTo => row["paymentTo"],
                        :amount => row["amount"],
                        :pmonth => row["paymentMonth"]
                      })
        end
      rescue Mysql2::Error => e
        reterr = e.message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end
    return {:retval => retval, :err => reterr}
  end

  def self.chkSearch y,m,o,a,e
    reterr = Array.new

    if y.nil? or (not y.is_a?(Integer))
      reterr.push("年指定が不正です。")
    end
    if m.nil? or (not m.is_a?(Integer)) or
        m<1 or 12<m
      reterr.push("月指定が不正です。")
    end
    if o.nil? or (not o.is_a?(String))
      reterr.push("対象者指定が不正です。")
    end
    if a.nil? or (not a.is_a?(String))
      reterr.push("対象口座指定が不正です。")
    end
    if e.nil? or (not e.is_a?(String))
      reterr.push("対象費目指定が不正です。")
    end

    return {:retval => (reterr.size==0), :err => reterr}
  end

  def self.search y,m,o,a,e
    retval = Array.new
    reterr = nil

    # input check
    chkrslt = chkSearch y,m,o,a,e
    unless chkrslt[:retval]
      reterr = chkrslt[:err]
    else
      wpdfrom =
        HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, m, 1))
      wpdto =
        HtmlUtil.fmtDtToStr(HtmlUtil.mkDt(y, m, -1))
      begin
        mysqlClient = getMysqlClient
        cond = " and wpdate between '#{wpdfrom}' and '#{wpdto}' "
        subquery = <<-SQL
          select sid, wpdate, eid, withdrawFrom as account,
                 -amount as amount, description
            from specifications
           where withdrawfrom is not null
                 #{cond}
          union
          select sid, wpdate, eid, paymentTo, amount, description
            from specifications
           where paymentto is not null
                 #{cond}
        SQL
        queryStr = <<-SQL
          select s.sid as sid, s.wpdate as wpdate, e.name as ename,
                 a.name as account, s.amount as amount,
                 s.description as description
            from (#{subquery}) s
                 left join expenditures e on s.eid=e.eid
                 left join accounts a on s.account=a.aid
        SQL
        condtmp = Array.new
        condtmp.push(" s.eid=#{e.to_i} ") unless e.empty?
        condtmp.push(" s.account=#{a.to_i} ") unless a.empty?
        condtmp.push(" a.uid='#{o}' ") unless o.empty?
        queryStr += " where " + condtmp.join(" and ") if condtmp.size>0

        rsltset = mysqlClient.query(queryStr)
        rsltset.each do |row|
          retval.push({ :sid => row["sid"],
                        :wpdate => row["wpdate"],
                        :ename => row["ename"],
                        :owner => row["account"],
                        :amount => row["amount"],
                        :desc => row["description"] })
        end
      rescue Mysql2::Error => e
        reterr = [e.message]
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end

    return {:retval => retval, :err => reterr}
  end

  def self.ins(wpd, eid, wdFrom, pmTo, amount, pmonth, desc)
    retval = false
    reterr = nil
    
    tmperr = chkSpc({ :wpd => wpd, :eid => eid,
                      :wdFrom => wdFrom, :pmTo => pmTo,
                      :amount => amount, :pmonth => pmonth })
    
    if tmperr.size <= 0
      begin
        mysqlClient = getMysqlClient
        queryStr = <<-SQL
          insert into specifications(wpdate, EID, amount
        SQL
        queryStr += " , withdrawFrom " unless wdFrom.nil?
        queryStr += " , paymentTo " unless pmTo.nil?
        queryStr += " , paymentMonth" unless pmonth.nil?
        queryStr += " , description " unless desc.nil?
        queryStr += " )values( "
        wpddt = HtmlUtil.fmtDtToStr (HtmlUtil.fmtStrToDt wpd)
        tmparr = Array.new
        tmparr.push("'#{wpddt}'").push(eid.to_s).push(amount.to_s)
        tmparr.push(wdFrom.to_s) unless wdFrom.nil?
        tmparr.push(pmTo.to_s) unless pmTo.nil?
        tmparr.push(pmonth.to_s) unless pmonth.nil?
        tmparr.push("'#{desc}'") unless desc.nil?
        queryStr += tmparr.join(",") + ")"

        mysqlClient.query(queryStr)

        retval = (mysqlClient.affected_rows > 0)
      rescue Mysql2::Error => e
        reterr = [e.message, queryStr]
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    else
      reterr = tmperr
    end
    return {:retval => retval, :err => reterr}
  end

  def self.updPaymentMonth(sid, pmonth)
    retval = false
    reterr = nil
    begin
      mysqlClient = getMysqlClient
    rescue Mysql2::Error => e
      
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end
end
