# encoding: utf-8
# Specifications model (明細)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

=begin
create table specifications (
       SID bigint auto_increment primary key,
       wpdate datetime, -- withdraw or payment
       EID bigint,
       withdrawFrom bigint,
       paymentTo bigint,
       amount bigint,
       paymentMonth datetime
);
=end

class Specification < ModelMaster
  def self.listSpc(from=nil,to=nil)
    retval = Array.new
    reterr = nil
    begin
      # TODO: input check from, to

      queryStr = <<-SQL
        select SID, wpdate, EID, withdrawFrom, paymentTo,
               amount, paymentMonth
          from specifications
      SQL
      # TODO: add condition of from, to
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
    return {:retval => retval, :err => reterr}
  end

  def self.insSpc(wpd, eid, wdFrom, pmTo, amount, pmonth)
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
