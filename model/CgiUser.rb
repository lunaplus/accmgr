# -*- coding: utf-8 -*-
# encording: utf-8
# cgiUsers model
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

class CgiUser < ModelMaster
  UIDLENGTH=8
  NAMELENGTH=20

  def self.updateUser(curuid,upuid="",upname="",uppass="")
    begin
      if (upuid == "" and upname == "" and uppass == "")
        return false, "UID, name, passいずれかに更新値を入力してください。"
      end
      mysqlClient = getMysqlClient
      curuidEscaped = mysqlClient.escape(curuid)
      upuidEscaped = mysqlClient.escape(upuid) unless upuid == ""
      upnameEscaped = mysqlClient.escape(upname) unless upname == ""
      uppassEscaped = mysqlClient.escape(HtmlUtil.digestPassword uppass) unless uppass == ""

      queryStr = "update cgiUsers set"
      tmpArr = []
      tmpArr.push(" uid = '#{upuidEscaped}' ") unless upuid == ""
      tmpArr.push(" name = '#{upnameEscaped}' ") unless upname == ""
      tmpArr.push(" password = '#{uppassEscaped}' ") unless uppass == ""
      queryStr += tmpArr.join(",")
      queryStr += " where uid = '#{curuidEscaped}' "

      mysqlClient.query(queryStr)
      return {:isSucc => true, :errmsg => ""}
    rescue Mysql2::Error => e
      return {:isSucc => false, :errmsg => e.message}
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
  end

  def self.authUser(uid, pass)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      passEscaped = mysqlClient.escape(HtmlUtil.digestPassword pass)
      queryStr = <<-QUERY
        select uid, password, name
        from cgiUsers
        where uid = '#{uidEscaped}' and password = '#{passEscaped}'
      QUERY
      rsltset = mysqlClient.query(queryStr)
      isAuth = rsltset.count != 0
      retUid = ""
      retName = ""
      rsltset.each do |row|
        retUid = row["uid"]
        retName = row["name"]
      end
      return {:isAuth => isAuth, :uid => retUid, :name => retName,
        :errmsg => ""}
    rescue Mysql2::Error => e
      return {:isAuth => false, :uid => "", :name => "", :errmsg => e.message}
    ensure
      mysqlClient.close
    end
  end

  def self.checkDuplicateName(name)
    retval = false # if not exist duplicat name, return true
    begin
      mysqlClient = getMysqlClient
      nameEsc = mysqlClient.escape(name)
      queryStr = <<-SQL
        select count(*) as counts from cgiUsers
         where name = '#{nameEsc}'
      SQL
      rsltSet = mysqlClient.query(queryStr)
      rsltSet.each do |row|
        retval = (row["counts"] == 0)
      end
      return {:isUnique => retval, :err => ""}
    rescue Mysql2::Error => e
      return {:isUnique => retval, :err => e.message}
    ensure
      mysqlClient.close
    end
  end

  def self.getUserList
    retval = Array.new
    iserr = false
    errstr = ""
    begin
      mysqlClient = getMysqlClient
      queryStr = <<-SQL
        select uid, name from cgiUsers
         order by uid
      SQL
      rsltSet = mysqlClient.query(queryStr)
      rsltSet.each do |row|
        retval.push({:uid => row["uid"], :name => row["name"]})
      end
    rescue Mysql2::Error => e
      iserr = true
      errstr = e.message
    ensure
      mysqlClient.close
    end
    return {:ulist => retval, :iserr => iserr, :errstr => errstr}
  end

=begin
  def self.getUser(uid)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      queryStr = <<-QUERY
        select uid, name
        from cgiUsers
        where uid = '#{uidEscaped}'
      QUERY
      rsltset = mysqlClient.query(queryStr)
      retUid = ""
      retName = ""
      rsltset.each do |row|
        retUid = row["uid"]
        retName = row["name"]
      end
      return retName,""
    rescue Mysql2::Error => e
      return "",e.message
    ensure
      mysqlClient.close
    end
  end
=end

end
