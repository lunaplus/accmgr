# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require 'erb'
require 'pathname'

class MainController
  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"

    menuList = HtmlUtil.getMenuList(HtmlUtil.getMainUrl)

    actionUrl = HtmlUtil.getMainUrl "update"

    yearsel = HtmlUtil.createYearSel 1,-10,10
    monthsel = HtmlUtil.createMonthSel
    datesel = HtmlUtil.createDateSel

    expsel = ""

    wFromsel = ""
    pTosel = ""

    paymonthsel = HtmlUtil.createMonthSel 0,false

    form = Pathname("view/Main.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
