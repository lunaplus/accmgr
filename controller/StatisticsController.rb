# encoding: utf-8
# Statistics Controller
require_relative '../util/HtmlUtil'
require 'erb'
require 'pathname'

class StatisticsController
  UPDERR = "STATUPDERR"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getStatUrl)

    errorstr = session[UPDERR]
    errorstr = "" if errorstr.nil?
    session[UPDERR] = nil

    form = Pathname("view/Stat.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
