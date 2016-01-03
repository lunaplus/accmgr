# -*- coding: utf-8 -*-
# CGI Initialize class
require 'date'
require 'digest/sha2'
require 'cgi'
require_relative '../model/CgiUser'
require_relative '../model/Expenditure'
require_relative '../model/Account'

class HtmlUtil
  LOGINID = "loginid"
  LOGINNAME = "loginname"
  ISADMIN = "isAdmin"

  LoginCtrlName = "login"
  MenuCtrlName = "menu"
  MainCtrlName = "main"
  AccCtrlName = "acc"

  URLROOT = "/accmgr"

  REGDTFMT = "%Y-%m-%d %H:%M:%S" # regular datetime format
  REGDFMT1 = "%Y-%m-%d" # regular date format (used in datetime)
  REGDFMT2 = "%Y/%m/%d" # regular date format (used in datetime)

  CHKEDIT = "chkEdit"
  HIDAID = "hidAID"
  TXTNM = "txtName"
  CHKISCD = "chkIscard"
  CHKISCDCHK = CHKISCD + "_chk"
  SELUID = "selUID"
  TXTBL = "txtBalance"
  LBLDT = "lblDate"

  def self.htmlHeader
    ret = <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset-='UTF-8'>
    <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes" />
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

  def self.getAccUrl act="index"
    return (createUrl AccCtrlName,act)
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
    accmgmtUrl = HtmlUtil.getAccUrl

    mainUrl = "#" if HtmlUtil.getMainUrl == now
    personMgmtUrl = "#" if HtmlUtil.getMenuUrl("person") == now
    accmgmtUrl = "#" if HtmlUtil.getAccUrl == now

    menuList = <<-MENU
        <li><a href="#{mainUrl}">メイン画面へ</a></li>
	<li><a href="#{personMgmtUrl}">自分の管理</a></li>
        <li><a href="#{accmgmtUrl}">口座管理画面へ</a></li>
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

## return select box of date
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

## return select box of Expenditure
  def self.expSel arg=nil
    explist = Expenditure.list arg
    if not explist[:err].nil?
      retval = "<option>" + explist[:err] + "</option>"
    else
      retval = "<option value=\"\"></option>"
      explist[:retval].each do |elm|
        retval += "<option value=\"#{elm[:eid]}\">"
        retval += "#{elm[:name]}</option>"
      end
    end

    return retval
  end

  def self.accSel
    acclist = Account.list
    if not acclist[:err].nil?
      retval = "<option>" + acclist[:err] + "</option>"
    else
      retval = "<option value=\"\"></option>"
      acclist[:retval].each do |elm|
        retval += "<option value=\"#{elm[:AID]}\">"
        retval += "#{elm[:name]}</option>"
      end
    end
    return retval
  end

  def self.usrSel uid=nil
    usrlist = CgiUser.getUserList
    retval = ""

    if usrlist[:iserr]
      retval += "<option>" + usrlist[:errstr] + "</option>"
    else
      retval += "<option value=\"\"></option>"
      usrlist[:ulist].each do |elm|
        retval += "<option value\"#{elm[:uid]}\""
        retval += " selected" if (not uid.nil?) and uid=elm[:uid]
        retval += ">#{elm[:name]}</option>"
      end
    end

    return retval
  end

  def self.accTblList trid, tdid
    acclist = Account.list
    retval = ""

    if not acclist[:err].nil?
      retval = "<tr><td>" + acclist[:err] + "</td></tr>"
    else
      selusr = usrSel
      retval += <<-HEAD
        <tr>
          <th>編集</th>
          <th>口座名</th>
          <th>カード区分</th>
          <th>所有者</th>
          <th>残高</th>
          <th>追加・更新日</th>
        </tr>
        <tr id="#{trid}0">
          <td id="#{tdid+CHKEDIT}0">
            <input type="checkbox" name="#{CHKEDIT}"
                   id="#{CHKEDIT}0">
            <input type="hidden" name="#{HIDAID}"
                   disabled="disabled"
                   id="#{HIDAID}0" value=""></td>
          <td id="#{tdid+TXTNM}0">
            <input type="textbox" name="#{TXTNM}"
                   disabled="disabled" id="#{TXTNM}0" value=""></td>
          <td id="#{tdid+CHKISCD}0">
            <input type="checkbox" name="#{CHKISCDCHK}"
                   disabled="disabled" id="#{CHKISCDCHK}0"></td>
            <input type="hidden" name="#{CHKISCD}"
                   disabled="disabled"
                   id="#{CHKISCD}0" value="off"></td>
          <td id="#{tdid+SELUID}0">
            <select name="#{SELUID}" id="#{SELUID}0" disabled="disabled">
            #{selusr}
            </select></td>
          <td id="#{tdid+TXTBL}0">
            <input type="textbox" name="#{TXTBL}" id="#{TXTBL}0"
                   disabled="disabled" value=""></td>
          <td id="#{tdid+LBLDT}0"></td>
        </tr>
      HEAD
      0.upto(acclist[:retval].size-1) do |i|
        row = acclist[:retval][i]
        j = (i+1).to_s
        # edit checkbox, ID(hidden)
        retval += <<-CHK
        <tr id=\"#{trid+j}>\">
          <td id="#{tdid+CHKEDIT+j}">
            <input type="checkbox" name="#{CHKEDIT}"
                   id="#{CHKEDIT+j}">
            <input type="hidden" name="#{HIDAID}"
                   id="#{HIDAID+j}" disabled="disabled"
                   value="#{row[:AID]}"></td>
        CHK
        # name textbox
        retval+= <<-NAME
          <td id="#{tdid+TXTNM+j}">
            <input type="textbox" name="#{TXTNM}"
                   id="#{TXTNM+j}" disabled="disabled"
                   value="#{row[:name]}"></td>
        NAME
        # iscard chkbox
        retval += <<-ISCD
          <td id="#{tdid+CHKISCD+j}">
            <input type="checkbox" name="#{CHKISCDCHK}"
                   id="#{CHKISCDCHK+j}" disabled="disabled"
        ISCD
        retval += "          checked=\"checked\"" if row[:iscard]
        retval += ">"
        retval += <<-ISCD2
            <input type="hidden" name="#{CHKISCD}"
                   id="#{CHKISCD+j}" disabled="disabled"
        ISCD2
        retval += (row[:iscard] ? " value=\"on\">" : " value=\"off\">")
        retval += "</td>"

        # UID, uname selectbox
        selusr = usrSel(row[:UID])
        retval += <<-USR
          <td id="#{tdid+SELUID+j}">
            <select name="#{SELUID}" id="#{SELUID+j}" disabled="disabled">
            #{selusr}
          </select></td>
        USR
        # balance textbox(number)
        retval += <<-BALANCE
          <td id="#{tdid+TXTBL+j}">
            <input type="textbox" name="#{TXTBL}" id="#{TXTBL+j}"
                   disabled="disabled"
                   value="#{row[:balance].to_s}">
          </td>
        BALANCE
        # adddate,editdate label
        ldate = fmtDtToStr(row[:adddate])
        ldate += "<br>" + fmtDtToStr(row[:editdate])
        retval += <<-DATE
          <td id="#{tdid+LBLDT+j}">#{ldate}</td>
        DATE
        retval += "</tr>"
      end
    end

    return retval
  end

## date utilities
  # create
  def self.getDtToday
    return DateTime.now
  end
  def self.mkDt y,m,d
    return DateTime.new(y,m,d)
  end

  # cast from datetime to string (DB -> Str, DateTime -> DB(str))
  def self.fmtDtToStr dt
    return dt.strftime(REGDTFMT)
  end

  # cast from string to datetime
  def self.fmtStrToDt str
    retval = nil
    arr = [REGDTFMT, REGDFMT1, REGDFMT2]
    arr.each do |fmt|
      begin
        retval = DateTime.strptime(str,fmt)
        break
      rescue ArgumentError
      end
    end
    return retval
  end

## ===================================================================
=begin # no use

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

  def self.parseDateTime date
    return (date+Rational(9,24))
    # return ((DateTime.strptime(date, "%Y-%m-%d %H:%M:%S"))+Rational(9,24))
  end

  def self.parseDate str
    return Date.parse(str, "%Y-%m-%d")
  end

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
