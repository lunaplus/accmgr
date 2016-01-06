# encoding: utf-8
# Statistics Controller
require_relative '../util/HtmlUtil'
require 'erb'
require 'pathname'

class StatisticsController
  UPDERR = "STATUPDERR"

  SELYEAR = "selyear"
  SELMONTH = "selmonth"
  SELOWNER = "selowner"
  SELACC = "selaccount"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getStatUrl)

    errorstr = session[UPDERR]
    errorstr = "" if errorstr.nil?
    session[UPDERR] = nil

    selyear = HtmlUtil.createYearSel 0,-5,1
    selmonth = HtmlUtil.createMonthSel 0,false
    selmonth = "<option value=\"all\">全期間</option>\n" + selmonth

    selowner = HtmlUtil.getUserSel(login) #TODO: "全員"の追加

    #TODO: 全口座の追加、selownerの選択に対応する対象の表示
    selacc = HtmlUtil.accSel

    form = Pathname("view/Stat.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
