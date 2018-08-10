# encoding: utf-8
# Accounts model (口座)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'
require_relative './CgiUser'

=begin
create table accounts (
       AID bigint auto_increment primary key,
       name varchar(20),
       isCard bit(1) not null default b'0',
       UID varchar(8),
       balance bigint unsigned,
       adddate datetime,
       editdate datetime
);
=end

class Account < ModelMaster
  C_AIDERR = "口座IDを指定してください。"

  def self.chkAcc(arg)
=begin
{:name => name, :iscard => iscard, :uid => uid,
 :balance => balance, :isins => isins}
=end
    retval = Array.new

    if arg.nil? or (not arg.instance_of?(Hash)) or
        (not arg.has_key?(:isins))
      retval.push("引数の型を確認してください。")
      return retval
    end
    isins = arg[:isins]
    name = arg[:name]
    iscard = arg[:iscard]
    uid = arg[:uid]
    balance = arg[:balance]
    if isins and
        (name.nil? or iscard.nil? or uid.nil? or balance.nil?)
      retval.push("name, iscard, uid, balanceは必須です。")
    elsif (not isins) and
        (name.nil? and iscard.nil? and uid.nil? and
         balance.nil?)
      retval.push("name, iscard, uid, balanceの" +
                  "いずれか1つ以上指定してください。")
    else
      if (isins or (not name.nil?)) and (not name.instance_of?(String))
        retval.push("口座名は文字列で指定してください。")
      end
      # iscardは型チェックなし
      if (isins or (not uid.nil?)) and (not CgiUser.isExist?(uid))
        retval.push("存在しない所有者IDです。")
      end
      if (isins or (not balance.nil?)) and
          ((not balance.is_a?(Integer)) or (balance < 0))
        retval.push("口座残高は正数で入力してください。")
      end
    end

    return retval
  end
  private_class_method :chkAcc

  def self.ins(name, iscard, uid, balance)
    retval = false
    reterr = nil

    tmperr = chkAcc({ :isins => true, :name => name,
                      :iscard => iscard, :uid => uid,
                      :balance => balance })
    if tmperr.size != 0
      reterr = tmperr
    else
      iscstr = iscard ? "true" : "false"
      begin
        mysqlClient = getMysqlClient
        queryStr = <<-SQL
          insert into accounts(name, isCard, UID, balance, adddate, editdate)
                 values('#{name}', #{iscstr}, '#{uid}', #{balance.to_s},
                        now(), now())
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

  def self.list
    retval = Array.new
    reterr = nil

    begin
      mysqlClient = getMysqlClient
      queryStr = <<-SQL
        select AID, accounts.name as name, isCard+0 as iscard,
               accounts.UID as UID, cgiUsers.name as uname, balance,
               adddate, editdate
          from accounts left join cgiUsers on accounts.UID = cgiUsers.UID
         order by AID
      SQL
      rsltset = mysqlClient.query(queryStr)

      rsltset.each do |row|
        retval.push({
                      :AID => row["AID"],
                      :name => row["name"],
                      :iscard => (row["iscard"] == 1),
                      :UID => row["UID"],
                      :uname => row["uname"],
                      :balance => row["balance"],
                      :adddate => row["adddate"],
                      :editdate => row["editdate"]
                    })
      end
    rescue Mysql2::Error => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end

    return {:retval => retval, :err => reterr}
  end

  def self.upd(aid, name, iscard, uid, balance)
    retval = false
    reterr = nil

    if not aid.is_a?(Integer)
      reterr = ["口座IDの型が不正です。"]
    else
      tmperr = chkAcc({ :isins => false, :name => name,
                        :iscard => iscard, :uid => uid,
                        :balance => balance })
      if tmperr.size != 0
        reterr = tmperr
      else
        begin
          mysqlClient = getMysqlClient
          queryStr = <<-SQL
            update accounts set
          SQL
          tmparr = Array.new
          tmparr.push(" name = '#{name}' ") unless name.nil?
          unless iscard.nil?
            iscstr = iscard ? "true" : "false"
            tmparr.push(" isCard = #{iscstr} ")
          end
          tmparr.push(" UID = '#{uid}' ") unless uid.nil?
          tmparr.push(" balance = #{balance.to_s} ") unless balance.nil?
          tmparr.push(" editdate = now() ")
          queryStr += tmparr.join(",")
          queryStr += " where AID = #{aid.to_s} "
          mysqlClient.query(queryStr)

          retval = (mysqlClient.affected_rows > 0)
        rescue Mysql2::Error => e
          reterr = [e.message]
        ensure
          mysqlClient.close unless mysqlClient.nil?
        end
      end
    end

    return {:retval => retval, :err => reterr}
  end

  def self.addBalance(aid, add)
    retval = false
    reterr = nil

    if not aid.is_a?(Integer)
      reterr = "口座IDの型が不正です。"
    else
      if add.nil? or (not add.is_a?(Integer))
        reterr = "口座残高への加減算は正数で入力してください。"
      else
        begin
          mysqlClient = getMysqlClient
          queryStr = <<-SQL
            update accounts set
                   balance = balance + #{add.to_s}
             where AID = #{aid.to_s}
          SQL
          mysqlClient.query(queryStr)

          retval = (mysqlClient.affected_rows > 0)
        rescue Mysql2::Error => e
          reterr = e.message
        ensure
          mysqlClient.close unless mysqlClient.nil?
        end
      end
    end

    return {:retval => retval, :err => reterr}
  end

  def self.isExist? aid
    retval = false

    if (not aid.is_a?(Integer))
      # no return error message
    else
      begin
        mysqlClient = getMysqlClient
        queryStr = "select 1 from accounts where AID = #{aid.to_s}"
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

  def self.foundByName? name
    retval = false

    if (name.is_a?(String))
      begin
        mysqlClient = getMysqlClient
        queryStr = "select 1 from accounts where name = '#{name}'"
        rsltset = mysqlClient.query(queryStr)

        retval = (rsltset.size > 0)
      rescue Mysql2::Error => e
        # no return error message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    else
      # nothing to do when type error
    end

    return retval
  end

  def self.getAidByName name
    retval = nil
    reterr = nil

    if (name.is_a?(String))
      begin
        mysqlClient = getMysqlClient
        queryStr = "select aid from accounts where name = '#{name}'"
        rsltset = mysqlClient.query(queryStr)

        if(rsltset.size == 1)
          rsltset.each do |row|
            retval = row["aid"]
          end
        else
          reterr = "同名の口座が複数存在するため、" +
                   "対象を特定できません"
        end
      rescue Mysql2::Error => e
        reterr = e.message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    else
      reterr = "引数には文字列(口座名)をセットしてください。(" +
               name.class.to_s + "/" + name.to_s + ")"
    end

    return { :retval => retval, :reterr => reterr }
  end
end
