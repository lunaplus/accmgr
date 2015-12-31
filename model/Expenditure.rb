# encoding: utf-8
# Expenditures model (費目)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

=begin
create table expenditures (
       EID bigint auto_increment primary key,
       name varchar(20),
       classify	bit(1)
);
-- classify : b'1'=>in, b'0'=>out, null=>move
=end

class Expenditure < ModelMaster
  C_IN = 1
  C_OUT = 2
  C_MOVE = 3
  C_DBIN = 1
  C_DBOUT = 0

  C_MAXNAMELEN = 20

  C_EXPNAMEERR = "費目名は20文字以内で指定してください。"
  C_CLASSIFYERR = "収支区分は1(in),2(out),3(move)のいずれかにて" +
    "指定してください。"
  C_EIDERR = "費目IDを指定してください。"

  def self.clsfyToDbVal(clsfy)
    iserr = false

    case clsfy
    when C_IN then
      cls = "b'" + C_DBIN.to_s + "'"
    when C_OUT then
      cls = "b'" + C_DBOUT.to_s + "'"
    when C_MOVE then
      cls = "null"
    else
      cls = "収支区分に予期せぬ値が指定されました。"
      iserr = true
    end

    return {:retval => cls, :err => iserr}
  end
  private_class_method :clsfyToDbVal

  def self.ins(expName, clsfy)
    retval = false
    reterr = nil
    begin
      if expName.nil? or (not expName.instance_of?(String)) or
          expName.length < 1 or expName.length > C_MAXNAMELEN
        reterr = C_EXPNAMEERR
      elsif (not clsfy.is_a?(Integer)) or clsfy < C_IN or clsfy > C_MOVE
        reterr = C_CLASSIFYERR
      else
        tmpcls = clsfyToDbVal(clsfy)
        if tmpcls[:err]
          raise Exception.new(tmpcls[:retval])
        else
          cls = tmpcls[:retval]
        end
        mysqlClient = getMysqlClient
        enEsc = mysqlClient.escape(expName)
        queryStr = <<-SQL
          insert into expenditures(name, classify)
               values('#{enEsc}', #{cls})
        SQL
        mysqlClient.query(queryStr)
        retval = (mysqlClient.affected_rows > 0)
      end
    rescue Mysql2::Error => e
      reterr = e.message
    rescue Exception
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end

  def self.upd(eid, expName=nil, clsfy=nil)
    retval = false
    reterr = nil
    begin
      if eid.nil? or (not eid.is_a?(Integer))
        reterr = C_EIDERR
      elsif expName.nil? and clsfy.nil?
        reterr = "費目名または収支区分のいずれか１つ以上指定してください。"
      elsif (not expName.nil?) and
          (   (not expName.instance_of?(String)) or
              expName.length < 1 or expName.length > C_MAXNAMELEN)
        reterr = C_EXPNAMEERR
      elsif (not clsfy.nil?) and
          ((not clsfy.is_a?(Integer)) or clsfy < C_IN or clsfy > C_MOVE)
        reterr = C_CLASSIFYERR
      else
        unless clsfy.nil?
          tmpcls = clsfyToDbVal(clsfy)
          if tmpcls[:err]
            raise Exception.new(tmpcls[:retval])
          else
            cls = tmpcls[:retval]
          end
        else
          cls = nil
        end
        mysqlClient = getMysqlClient
        enEsc = (expName.nil? ? nil : mysqlClient.escape(expName))
        queryStr = " update expenditures set "
        tmpArr = Array.new
        tmpArr.push(" name = '#{enEsc}' ") unless expName.nil?
        tmpArr.push(" classify = #{cls} ") unless clsfy.nil?
        queryStr += tmpArr.join(",")
        queryStr += " where EID = #{eid.to_s}"

        mysqlClient.query(queryStr)
        retval = (mysqlClient.affected_rows > 0)
      end
    rescue Mysql2::Error => e
      reterr = e.message
    rescue Exception => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end

  def self.del(eid)
    retval = false
    reterr = nil
    begin
      if eid.nil? or (not eid.is_a?(Integer))
        reterr = C_EIDERR
      else
        queryStr = " delete from expenditures where EID = #{eid.to_s} "
        mysqlClient = getMysqlClient
        mysqlClient.query(queryStr)

        retval = (mysqlClient.affected_rows > 0)
      end
    rescue Mysql2::Error => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end

  def self.list arg=nil
    retval = Array.new
    reterr = nil

    tmpcls = (arg.nil? ? {:err => false} : clsfyToDbVal(arg))
    unless tmpcls[:err]
      queryStr =
        " select EID, name, classify+0 as cls from expenditures "
      unless arg.nil?
        queryStr += " where classify "
        if arg == C_MOVE
          queryStr += " is " + tmpcls[:retval]
        else
          queryStr += " = " + tmpcls[:retval]
        end
      end
      queryStr += " order by EID "
      begin
        mysqlClient = getMysqlClient
        rsltSet = mysqlClient.query(queryStr)
        
        rsltSet.each do |row|
          case row["cls"]
          when C_DBIN
            tmpcls = C_IN
          when C_DBOUT
            tmpcls = C_OUT
          when nil
            tmpcls = C_MOVE
          else
          raise Exception.new("classifyが想定外です。 / " + row["cls"].to_s)
          end
          retval.push({:eid => row["EID"], :name => row["name"],
                        :cls => tmpcls})
        end
      rescue Mysql2::Error => e
        reterr = e.message
      rescue Exception => e
        reterr = e.message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end
    return {:retval => retval, :err => reterr}
  end

  def self.isExist?(eid)
    retval = false

    if eid.is_a?(Integer)
      begin
        mysqlClient = getMysqlClient
        queryStr = "select 1 from expenditures where EID = #{eid.to_s}"
        rsltset = mysqlClient.query(queryStr)

        retval = (rsltset.size > 0)
      rescue Mysql2::Error => e
        # no return error message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end

    return retval
  end
end