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

  C_MAXNAMELEN = 20

  C_EXPNAMEERR = "費目名は20文字以内で指定してください。"
  C_CLASSIFYERR = "収支区分は1(in),2(out),3(move)のいずれかにて" +
    "指定してください。"
  C_EIDERR = "費目IDを指定してください。"

  def self.clsfyToDbVal(clsfy)
    iserr = false

    case clsfy
    when C_IN then
      cls = "b'1'"
    when C_OUT then
      cls = "b'0'"
    when C_MOVE then
      cls = "null"
    else
      cls = "収支区分に予期せぬ値が指定されました。"
      iserr = true
    end

    return {:retval => cls, :err => iserr}
  end

  def self.insExp(expName, clsfy)
    retval = false
    reterr = nil
    begin
      if expName.nil? or expName.length < 1 or expName.length > C_MAXNAMELEN
        reterr = C_EXPNAMEERR
      elsif (not clsfy.instance_of?(Fixnum)) or clsfy < C_IN or clsfy > C_MOVE
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
        retval = true
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

  def self.updExp(eid, expName=nil, clsfy=nil)
    retval = false
    reterr = nil
    begin
      if eid.nil? or (not eid.instance_of?(Fixnum))
        reterr = C_EIDERR
      elsif expName.nil? and clsfy.nil?
        reterr = "費目名または収支区分のいずれか１つ以上指定してください。"
      elsif (not expName.nil?) and
          (expName.length < 1 or expName.length > C_MAXNAMELEN)
        reterr = C_EXPNAMEERR
      elsif (not clsfy.nil?) and
          ((not clsfy.instance_of?(Fixnum)) or clsfy < C_IN or clsfy > C_MOVE)
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
        retval = true
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

  def self.delExp(eid)
    retval = false
    reterr = nil
    begin
      if eid.nil? or (not eid.instance_of?(Fixnum))
        reterr = C_EIDERR
      else
        queryStr = " delete from expenditures where EID = #{eid.to_s} "
        mysqlClient = getMysqlClient
        mysqlClient.query(queryStr)

        retval = true
      end
    rescue Mysql2::Error => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end

  def self.listExp
    retval = Array.new
    reterr = nil
    begin
      queryStr =
        " select EID, name, classify from expenditures order by EID "
      mysqlClient = getMysqlClient
      rsltSet = mysqlClient.query(queryStr)

      rsltSet.each do |row|
        retval.push({:eid => row["EID"], :name => row["name"],
                      :cls => row["classify"]})
      end
    rescue Mysql2::Error => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end
end
