# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require_relative '../model/Specification'
require 'erb'
require 'pathname'

class MainController
  UPDERR = "MAINUPDERR"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"

    menuList = HtmlUtil.getMenuList(HtmlUtil.getMainUrl)

    actionUrl = HtmlUtil.getMainUrl "update"

    yearsel = HtmlUtil.createYearSel 0,-2,2
    monthsel = HtmlUtil.createMonthSel
    datesel = HtmlUtil.createDateSel

    inexpsel = HtmlUtil.expSel Expenditure::C_IN
    outexpsel = HtmlUtil.expSel Expenditure::C_OUT
    mvexpsel = HtmlUtil.expSel Expenditure::C_MOVE

    wFromsel = HtmlUtil.accSel
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
    pmonth = (args[0]["payMonth"][0]).to_i

    wpd = HtmlUtil.mkDt year,month,date

    case wpkinds
    when "withdraw" then
      exp = expin
      pto = nil
    when "payment" then
      exp = expout
      wfrom = nil
    when "accounttransfer" then
      exp = expmv
    else
      exp = nil
      pto = nil
      wfrom = nil
    end
    pmonth = nil if pmonth == 0

    rethash = Specification.ins((HtmlUtil.fmtDtToStr wpd), exp,
                                wfrom, pto, amounts, pmonth)
    session[UPDERR] =
      (HtmlUtil.arrToHtmlList rethash[:err],false) unless rethash[:retval]

    return "", true, (HtmlUtil.getMainUrl)
  end
end
