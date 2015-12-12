# -*- coding: utf-8 -*-
# CGI Initialize class
require 'date'
require 'digest/sha2'
require 'cgi'
require_relative '../model/CgiUser'

class HtmlUtil
  LOGINID = "loginid"
  LOGINNAME = "loginname"
  ISADMIN = "isAdmin"

  LoginCtrlName = "login"
  MenuCtrlName = "menu"
  MainCtrlName = "main"

  URLROOT = "/accmgr"

  def self.htmlHeader
    ret = <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset-='UTF-8'>
    <link rel="stylesheet" type="text/css" href="#{URLROOT}/css/accmgr.css">
  </head>
  <body>
    HTML
    return ret
  end

  def self.initCgi
    return {"charset" => "UTF-8", "status" => "OK"}
  end

  def self.htmlFooter
    ret = <<-HTML
</body></html>
    HTML
    return ret
  end

  def self.htmlRedirect cgi,url
    ret = cgi.header( { "status" => "REDIRECT", "Location" => url } )
    ret += <<-HTML
  <html>
    <head>
      <meta http-equiv="refresh" content"0;url=#{url}">
    </head>
    <body>
      wait...
    </body>
  </html>
    HTML
    return ret
  end

  def self.digestPassword s
    return Digest::SHA256.hexdigest(s)
  end

  def self.getUrlRoot
    if ENV['HTTPS'] == "on"
      urlRoot = "https://"
    else
      urlRoot = "http://"
    end

    urlRoot += ENV['HTTP_HOST'] + URLROOT
  end

  def self.getMenuUrl(action = "index")
    return (createUrl MenuCtrlName,action)
  end

  def self.getMainUrl act="index"
    return (createUrl MainCtrlName,act)
  end

  def self.createUrl ctrl,act="",arg=nil
    ret = getUrlRoot + "/" + ctrl
    ret += "/" + act unless act == ""
    ret += "/" + (arg.join("/")) unless arg == nil or arg.size < 1
    return ret
  end

  def self.esc(str)
    return CGI.escapeHTML(str)
  end

  def self.unesc(str)
    return CGI.unescapeHTML(str)
  end

  def self.getToday
    return DateTime.now
  end

  def self.fmtDateTime datetime
    #return (datetime-Rational(9,24)).strftime("%Y-%m-%d %H:%M:%S")
    return datetime.strftime("%Y-%m-%d %H:%M:%S")
  end

  def self.fmtDate date
    return date.to_s
  end

  def self.fmtTime datetime
    return datetime.strftime("%H:%M:%S")
  end

  def self.getUserSel (uid = nil)
    uHash = CgiUser.getUserList
    userSel = ""
    if uHash[:iserr]
      userSel = "<option value=\"0\">リスト取得異常(" +
        uHash[:errstr] + ")</option>"
    else
      uHash[:ulist].each do |elm|
        tmpid = elm[:uid].to_s
        tmpnm = elm[:name].to_s
        userSel += "<option value=\"#{tmpid}\""
        userSel += " selected " if !(uid.nil?) and uid == tmpid
        userSel += ">#{tmpnm}</option>"
      end
    end
    return userSel
  end

  def self.getMenuList(now = nil)
    mainUrl = HtmlUtil.getMainUrl
    personMgmtUrl = HtmlUtil.getMenuUrl("person")

    mainUrl = "#" if HtmlUtil.getMainUrl == now
    personMgmtUrl = "#" if HtmlUtil.getMenuUrl("person") == now

    menuList = <<-MENU
        <li><a href="#{mainUrl}">メイン画面へ</a></li>
	<li><a href="#{personMgmtUrl}">自分の管理</a></li>
    MENU
    return menuList
  end

  def self.arrToHtmlList(arr, isOdr)
    retstr = (isOdr ? "<ol>" : "<ul>")
    if arr.count == 0
      retstr = "<li>リストアイテムが空です。</li>"
    else
      arr.each do |elm|
        retstr += "<li>" + elm + "</li>" unless elm.nil?
      end
    end
    retstr += (isOdr ? "</ol>" : "</ul>")
    return retstr
  end

  def self.parseDateTime date
    return (date+Rational(9,24))
    # return ((DateTime.strptime(date, "%Y-%m-%d %H:%M:%S"))+Rational(9,24))
  end

  def self.parseDate str
    return Date.parse(str, "%Y-%m-%d")
  end

  def self.createYearSel sel=0,from=-1,to=1
    # year sel : 入力日とその前後1年分の年数を表示する。デフォルトは当年。
    today = Time.now
    defyear = today.year + sel
    retyear = ""
    min = today.year + (from < to ? from : to)
    max = today.year + (from <= to ? to : from)
    min.upto(max) do |i|
      retyear += "<option value=\"#{i}\""
      retyear += " selected " if i == defyear
      retyear += ">#{i}</option>"
    end
    return retyear
  end

  def self.createMonthSel df=0,dfset=true
    # month sel : 12ヶ月分全部表示する。デフォルトは当月
    today = Time.now
    defaultSel = df
    defaultSel = today.month if df < 1 or df > 12

    monthSel = ""
    1.upto(12) do |i|
      monthSel += "<option value=\"#{i}\""
      monthSel += " selected" if i == defaultSel and dfset
      monthSel += ">#{i}</option>\n"
    end
    return monthSel
  end

  def self.createDateSel df=0
    # date sel : 31日分全部表示する。デフォルトは当日
    today = Time.now
    defaultSel = df-1
    defaultSel = today.day if df < 1 or df > 31

    dateSel = ""
    1.upto(31) do |i|
      dateSel += "<option value=\"#{i}\""
      dateSel += " selected" if i == defaultSel
      dateSel += ">#{i}</option>\n"
    end
    return dateSel
  end

## ===================================================================
=begin # no use

  def self.createDate y,m,d
    return Date.new(y,m,d)
  end

  def self.createDateTime y,m,d,h=0,mi=0,s=0
    return DateTime.new(y,m,d,h,mi,s,Rational(9,24))
  end
=end
end

class Integer
  def to_currency()
    self.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end
end
