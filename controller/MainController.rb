# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require_relative '../model/Specification'
require_relative '../model/Account'
require 'erb'
require 'pathname'

class MainController
  UPDERR = "MAINUPDERR"
  PREVYEAR = "Main.year"
  PREVMONTH = "Main.month"
  PREVDATE = "Main.date"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"

    menuList = HtmlUtil.getMenuList(HtmlUtil.getMainUrl)

    actionUrl = HtmlUtil.getMainUrl "update"

    # 直前の入力年月日を保持する
    prevyear = (session[PREVYEAR].nil? ? 0
                : (session[PREVYEAR] - Time.now.year))
    prevmonth = (session[PREVMONTH].nil? ? Time.now.month
                 : session[PREVMONTH])
    prevdate = (session[PREVDATE].nil? ? 0 : session[PREVDATE]+1)
    session[PREVYEAR] = nil
    session[PREVMONTH] = nil
    session[PREVDATE] = nil

    yearsel = HtmlUtil.createYearSel prevyear,-2,2
    monthsel = HtmlUtil.createMonthSel prevmonth
    datesel = HtmlUtil.createDateSel prevdate

    inexpsel = HtmlUtil.expSel(Expenditure::C_IN, nil, true, true)
    outexpsel = HtmlUtil.expSel(Expenditure::C_OUT, nil, true, true)
    mvexpsel = HtmlUtil.expSel(Expenditure::C_MOVE, nil, true, true)

    wFromsel = "<option value=\"\"></option>" + HtmlUtil.accSel
    pTosel = wFromsel.clone

    paymonthsel = HtmlUtil.createMonthSel 0,false

    errorstr = session[UPDERR]
    errorstr = "" if errorstr.nil?
    session[UPDERR] = nil

    form = Pathname("view/Main.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def update session,args
    year = (args[0]["yearsel"][0]).to_i
    month = (args[0]["monthsel"][0]).to_i
    date = (args[0]["datesel"][0]).to_i
    wpkinds = args[0]["wpkinds"][0]
    expin = args[0]["expin"][0].to_i
    expout = args[0]["expout"][0].to_i
    expmv = args[0]["expmv"][0].to_i
    wfrom = (args[0]["withdrawFrom"][0]).to_i
    pto = (args[0]["paymentTo"][0]).to_i
    amounts = (args[0]["amounts"][0]).gsub(',','').to_i
    desc = args[0]["desc"][0]
    pmonth = (args[0]["payMonth"][0]).to_i
    chkLoan = (args[0]["chkLoan"][0] == "on")
    loan = (chkLoan==true ? Specification::LOAN_LOANING : nil)

    begin
      wpd = HtmlUtil.mkDt year,month,date
    rescue ArgumentError => e
      wpd = nil
    end

    case wpkinds
    when "withdraw" then
      exp = expin
      wfrom = nil
    when "payment" then
      exp = expout
      pto = nil
    when "accounttransfer" then
      exp = expmv
    else
      exp = nil
      pto = nil
      wfrom = nil
    end
    pmonth = nil if pmonth == 0
    desc = nil if desc.empty?

    tmpupderr = Array.new
    if wpd.nil?
      tmpupderr += ["日付入力が不正です。" +
                    "/ year : " + year.to_s +
                    ", month : " + month.to_s +
                    ", date : " + date.to_s]
    else
      if (not wfrom.nil?)
        rethash = Account.addBalance(wfrom, -amounts)
        tmpupderr += [rethash[:err]] unless rethash[:err].nil?
      end
      if tmpupderr.empty?
        rethash = Specification.ins((HtmlUtil.fmtDtToStr wpd), exp,
                                    wfrom, pto, amounts, pmonth, desc, loan)
        tmpupderr += rethash[:err] unless rethash[:err].nil?
      end
      if tmpupderr.empty? and (not pto.nil?)
        rethash = Account.addBalance(pto, amounts)
        tmpupderr += [rethash[:err]] unless rethash[:err].nil?
      end
    end

    # 直前の入力を保持する。
    session[PREVYEAR] = year
    session[PREVMONTH] = month
    session[PREVDATE] = date

    session[UPDERR] =
      (HtmlUtil.arrToHtmlList tmpupderr,false) unless tmpupderr.empty?

    return "", true, (HtmlUtil.getMainUrl)
  end
end
