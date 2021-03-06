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
  ExpCtrlName = "exp"
  StatCtrlName = "stscs"
  SpecCtrlName = "spec"
  LoanCtrlName = "loan"
  CsvCtrlName = "csv"
  ApiPrefix = "api"

  URLROOT = "/accmgr"

  REGDTFMT = "%Y-%m-%d %H:%M:%S" # regular datetime format
  REGDFMT1 = "%Y-%m-%d" # regular date format (used in datetime)
  REGDFMT2 = "%Y/%m/%d" # regular date format (used in datetime)

  CHKEDIT = "chkEdit"
  HIDAID = "hidAID"
  HIDEID = "hidEID"
  TXTNM = "txtName"
  CHKISCD = "chkIscard"
  CHKISCDCHK = CHKISCD + "_chk"
  SELUID = "selUID"
  SELCLSFY = "selClsfy"
  TXTBL = "txtBalance"
  LBLDT = "lblDate"
  SELFREEZE = "selFreeze"
  TXTSORTS = "txtSorts"

  def self.htmlHeader
    ret = <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset-='UTF-8'>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes" />
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Cache-Control" content="no-cache">
    <link rel="stylesheet" type="text/css" href="#{URLROOT}/css/accmgr.css">
  </head>
  <body>
    HTML
    return ret
  end

  def self.initCgi
    return {:charset => "UTF-8", :status => "OK"}
  end

  def self.getJsonHeader
    return ((initCgi)[:type] = "text/json")
  end

  def self.getPlainTextHeader
    return ((initCgi)[:type] = "text/plain")
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

  def self.getExpUrl act="index"
    return (createUrl ExpCtrlName,act)
  end

  def self.getStatUrl act="index"
    return (createUrl StatCtrlName,act)
  end

  def self.getSpecUrl act="index"
    return (createUrl SpecCtrlName,act)
  end

  def self.getLoanUrl act="index"
    return (createUrl LoanCtrlName,act)
  end

  def self.getCsvUrl act="index"
    return (createUrl CsvCtrlName,act)
  end

  def self.getApiAccUrl act
    return (createUrl ApiPrefix,AccCtrlName,[act])
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
    expmgmtUrl = HtmlUtil.getExpUrl
    specUrl = HtmlUtil.getSpecUrl
    statUrl = HtmlUtil.getStatUrl
    loanUrl = HtmlUtil.getLoanUrl
    csvUrl = HtmlUtil.getCsvUrl

    mainUrl = "#" if HtmlUtil.getMainUrl == now
    personMgmtUrl = "#" if HtmlUtil.getMenuUrl("person") == now
    accmgmtUrl = "#" if HtmlUtil.getAccUrl == now
    expmgmtUrl = "#" if HtmlUtil.getExpUrl == now
    specUrl = "#" if HtmlUtil.getSpecUrl == now
    statUrl = "#" if HtmlUtil.getStatUrl == now
    loanUrl = "#" if HtmlUtil.getLoanUrl == now
    csvUrl = "#" if HtmlUtil.getCsvUrl == now

    menuList = <<-MENU
<div id="menuarea">
  <ul id="normal" class="dropmenu">
    <li><label for="chkmenu">▼メニュー<label>
      <input type="checkbox" id="chkmenu">
      <ul>
        <li><a href="#{mainUrl}">メイン画面へ</a></li>
	<li><a href="#{personMgmtUrl}">自分の管理</a></li>
        <li><a href="#{accmgmtUrl}">口座管理画面へ</a></li>
        <li><a href="#{expmgmtUrl}">費目管理画面へ</a></li>
        <li><a href="#{statUrl}">統計画面へ</a></li>
        <li><a href="#{specUrl}">明細検索画面へ</a></li>
        <li><a href="#{loanUrl}">立替え清算画面へ</a></li>
        <li><a href="#{csvUrl}">CSVアップロード画面へ</a></li>
      </ul>
    </li>
  </ul>
</div>
    MENU
    return menuList
  end

  def self.arrToHtmlList(arr, isOdr)
    retstr = (isOdr ? "<ol>" : "<ul>")
    if arr.is_a?(Array)
      if arr.count == 0
        retstr = "<li>リストアイテムが空です。</li>"
      else
        arr.each do |elm|
          retstr += "<li>" + elm + "</li>" unless elm.nil?
        end
      end
    elsif arr.is_a?(String)
      retstr = "<li>" + arr + "</li>"
    else
      retstr = "<li>" + arr.to_s + "</li>"
    end
    retstr += (isOdr ? "</ol>" : "</ul>")
    return retstr
  end

  def self.fmtStatsList arr
    inall = "-"
    outall = "-"
    spceid = Array.new
    arr.each do |elm|
      if elm[:eid]==Statistic::ALLEIDIN
        inall = elm[:amount].to_currency
      elsif elm[:eid]==Statistic::ALLEIDOUT
        outall = elm[:amount].to_currency
      else
        spceid.push({:eid => elm[:eid], :amount => elm[:amount].to_currency})
      end
    end

    retval = <<-HTML
    <table id="dispStat">
      <tr><td>収入計</td>
      <td align="right">#{inall}</td></tr>
      <tr><td>支出計</td>
      <td align="right">#{outall}</td></tr>
      <tr><td colspan="2">
        費目別
        <table id="dispSpc">
    HTML
    spceid.each do |row|
      retval += <<-HTML
        <tr><td>#{row[:eid]}</td>
        <td align="right">#{row[:amount]}</td></tr>
      HTML
    end
    retval += <<-HTML
        </table>
      </td></tr>
    </table>
    HTML
    
    return retval
  end

  def self.fmtSpecList arr
    retval = <<-HTML
      <table>
        <tr>
          <th>日付</th>
          <th>費目</th>
          <th>口座</th>
          <th>金額</th>
          <th>詳細</th>
        </tr>
    HTML
    arr.each do |elm|
      retval += <<-HTML
        <tr id="#{elm[:sid]}">
          <td>#{fmtDtToShort(elm[:wpdate])}</td>
          <td>#{elm[:ename]}</td>
          <td>#{elm[:owner]}</td>
          <td style="text-align: right;">#{elm[:amount].to_currency}</td>
          <td>#{elm[:desc]}</td>
        </tr>
      HTML
    end

    retval += " </table> "
    return retval
  end

  def self.fmtLoaningList arr
    retval = <<-HTML
      <table>
        <tr>
          <th>支払者</th>
          <th>支払総額</th>
        </tr>
    HTML
    arr[:sums].each do |elm|
      retval += <<-HTML
        <tr>
          <td>#{elm[:owner]}</td>
          <td style="text-align: right;">#{elm[:amount].to_currency}</td>
        </tr>
      HTML
    end
    retval += <<-HTML
        <tr><td colspan="3">
        <table>
          <tr>
            <th>日付</th>
            <th>費目</th>
            <th>口座</th>
            <th>金額</th>
            <th>詳細</th>
          </tr>
    HTML
    arr[:lists].each do |elm|
      retval += <<-HTML
          <tr id="#{elm[:sid].to_s}">
            <td>#{fmtDtToShort(elm[:wpdate])}</td>
            <td>#{elm[:ename]}</td>
            <td>#{elm[:owner]}</td>
            <td style="text-align: right;">#{elm[:amount].to_currency}</td>
            <td>#{elm[:desc]}</td>
          </tr>
      HTML
    end
    retval += <<-HTML
        </td></tr>
      </table>
    HTML
  end

## return select box of date
  def self.createYearSel sel=0,from=-1,to=1
    # year sel : 入力日とその前後1年分の年数を表示する。デフォルトは当年。
    today = Time.now
    defyear = today.year + (sel.is_a?(Integer) ? sel : 0)
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

  def self.createMonthSel df,dfset=true
    # month sel : 12ヶ月分全部表示する。デフォルトは当月
    defaultSel = df

    monthSel = ""
    1.upto(12) do |i|
      monthSel += "<option value=\"#{i}\""
      monthSel += " selected" if dfset and i == defaultSel
      monthSel += ">#{i}</option>\n"
    end
    return monthSel
  end

  def self.createDateSel df=0
    # date sel : 31日分全部表示する。デフォルトは当日
    today = Time.now
    defaultSel = df-1
    defaultSel = today.day if df < 1 or df > 32

    dateSel = ""
    1.upto(31) do |i|
      dateSel += "<option value=\"#{i}\""
      dateSel += " selected" if i == defaultSel
      dateSel += ">#{i}</option>\n"
    end
    return dateSel
  end

## return select box of Expenditure
  def self.expSel cls=nil,arg=nil,frz=false,sorts=false
    explist = Expenditure.list(cls,frz,sorts)
    if not explist[:err].nil?
      retval = "<option>" + explist[:err] + "</option>"
    else
      retval = "<option value=\"\"></option>"
      i = 1
      explist[:retval].each do |elm|
        retval += "<option value=\"#{elm[:eid]}\""
        retval += " selected " if (not arg.nil?) and elm[:eid]==arg
        retval += ">#{i}:#{elm[:name]}</option>"
        i += 1
      end
    end

    return retval
  end

  def self.accSel arg=nil
    acclist = Account.list
    if not acclist[:err].nil?
      retval = "<option>" + acclist[:err] + "</option>"
    else
      retval = ""
      acclist[:retval].each do |elm|
        retval += "<option value=\"#{elm[:AID]}\""
        retval += " selected " if (not arg.nil?) and elm[:AID]==arg
        retval += ">#{elm[:AID]}:#{elm[:name]}</option>"
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
        retval += " selected" if ((not uid.nil?) and uid==elm[:uid])
        retval += ">#{elm[:uid]}</option>"
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

  def self.expClsfySel cls=nil
    retval = <<-OPT
        <option value=""></option>
    OPT
    retval += "<option value=\"#{Expenditure::C_IN}\""
    retval += " selected " if ((not cls.nil?) and cls==Expenditure::C_IN)
    retval += ">#{Expenditure::C_IN}(IN)</option>"

    retval += "<option value=\"#{Expenditure::C_OUT}\""
    retval += " selected " if ((not cls.nil?) and cls==Expenditure::C_OUT)
    retval += ">#{Expenditure::C_OUT}(OUT)</option>"

    retval += "<option value=\"#{Expenditure::C_MOVE}\""
    retval += " selected " if ((not cls.nil?) and cls==Expenditure::C_MOVE)
    retval += ">#{Expenditure::C_MOVE}(MOVE)</option>"

    return retval
  end

  def self.expFreezeSel frz=nil
    retval = ""
    retval += "<option value=\"#{Expenditure::C_NOFREEZED}\""
    retval += " selected " if (frz.nil? or frz==Expenditure::C_NOFREEZED)
    retval += ">#{Expenditure::C_NOFREEZED}(表示)</option>"

    retval += "<option value=\"#{Expenditure::C_FREEZED}\""
    retval += " selected " if ((not frz.nil?) and frz==Expenditure::C_FREEZED)
    retval += ">#{Expenditure::C_FREEZED}(非表示)</option>"

    return retval
  end

  def self.expTblList trid, tdid
    retval = ""
    explist = Expenditure.list(nil,false,true)

    unless explist[:err].nil?
      retval = "<tr><td>" + explist[:err] + "</td></tr>"
    else
      selclsfy = expClsfySel
      selfrz = expFreezeSel
      retval += <<-HEAD
        <tr>
          <th>編集</th>
          <th>費目名</th>
          <th>費目区分</th>
          <th>非表示</th>
          <th>ソート</th>
        </tr>
        <tr id="#{trid}0">
          <td id="#{tdid+CHKEDIT}0">
            <input type="checkbox" name="#{CHKEDIT}"
                   id="#{CHKEDIT}0">
            <input type="hidden" name="#{HIDEID}"
                   disabled="disabled"
                   id="#{HIDEID}0" value=""></td>
          <td id="#{tdid+TXTNM}0">
            <input type="textbox" name="#{TXTNM}"
                   disabled="disabled" id="#{TXTNM}0" value=""></td>
          <td id="#{tdid+SELCLSFY}0">
            <select name="#{SELCLSFY}" id="#{SELCLSFY}0" disabled="disabled">
            #{selclsfy}
            </select></td>
          <td id="#{tdid+SELFREEZE}0">
            <select name="#{SELFREEZE}" id="#{SELFREEZE}0" disabled="disabled">
            #{selfrz}
            </select></td>
          <td id="#{tdid+TXTSORTS}0">
            <input type="textbox" name="#{TXTSORTS}"
                   disabled="disabled" id="#{TXTSORTS}0" value=""></td>
        </tr>
      HEAD
      0.upto(explist[:retval].size-1) do |i|
        row = explist[:retval][i]
        j = (i+1).to_s
        # edit / EID(hidden)
        retval += <<-CHK
        <tr id=\"#{trid+j}>\">
          <td id="#{tdid+CHKEDIT+j}">
            <input type="checkbox" name="#{CHKEDIT}"
                   id="#{CHKEDIT+j}">
            <input type="hidden" name="#{HIDEID}"
                   id="#{HIDEID+j}" disabled="disabled"
                   value="#{row[:eid]}"></td>
        CHK
        # name
        retval+= <<-NAME
          <td id="#{tdid+TXTNM+j}">
            <input type="textbox" name="#{TXTNM}"
                   id="#{TXTNM+j}" disabled="disabled"
                   value="#{row[:name]}"></td>
        NAME
        # classify
        selclsfy = expClsfySel(row[:cls])
        retval += <<-CLSFY
          <td id="#{tdid+SELCLSFY+j}">
            <select name="#{SELCLSFY}" id="#{SELCLSFY+j}"
                    disabled="disabled">
            #{selclsfy}
          </select></td>
        CLSFY
        # freeze
        selfrz = expFreezeSel(row[:freeze])
        retval += <<-FRZ
          <td id="#{tdid+SELFREEZE+j}">
            <select name="#{SELFREEZE}" id="#{SELFREEZE+j}"
                    disabled="disabled">
            #{selfrz}
            </select></td>
        FRZ
        # sorts
        retval += <<-SORTS
          <td id="#{tdid+TXTSORTS+j}">
            <input type="textbox" name="#{TXTSORTS}"
                   disabled="disabled" id="#{TXTSORTS+j}"
                   value="#{row[:sorts]}"></td></tr>
        SORTS
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

  def self.fmtDtToShort dt
    return dt.strftime(REGDFMT1)
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
