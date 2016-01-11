# encoding: utf-8
# Statistics Controller
require_relative '../util/HtmlUtil'
require_relative '../model/Statistic'
require 'erb'
require 'pathname'

class StatisticsController
  UPDERR = "Stat.updErr"
  UPD_Y = "Stat.year"
  UPD_M = "Stat.month"
  UPD_O = "Stat.owner"
  UPD_A = "Stat.account"
  UPDRET = "Stat.getRet"

  SELYEAR = "selyear"
  SELMONTH = "selmonth"
  SELOWNER = "selowner"
  SELACC = "selaccount"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getStatUrl)

    actionUrl = HtmlUtil.getStatUrl("update")

    # error strings
    errorstr = ""
    errorstr =
      HtmlUtil.arrToHtmlList(session[UPDERR],false) unless session[UPDERR].nil?
    session[UPDERR] = nil

    # set post request state
    y = (session[UPD_Y].nil? ? 0 : (session[UPD_Y] - Time.now.year))
    m = (session[UPD_M].nil? ? 0 : session[UPD_M])
    msel = (not (m==0 or m==13))
    owner = (session[UPD_O].nil? ? login : session[UPD_O])
    acc = session[UPD_A]
    session[UPD_Y] = nil
    session[UPD_M] = nil
    session[UPD_O] = nil
    session[UPD_A] = nil

    # set select box values
    selyear = HtmlUtil.createYearSel y,-5,1
    selmonth = HtmlUtil.createMonthSel m,msel
    selmonth = "<option value=\"13\" #{msel ? "" : "selected"} >" + 
      "全期間</option>" + selmonth

    selowner = HtmlUtil.getUserSel(owner)
    selowner =
      "<option value=\"#{Statistic::ALLOWNERS}\">全員</option>" + selowner

    selacc = HtmlUtil.accSel (acc.to_i)
    selacc =
      "<option value=\"#{Statistic::ALLACC}\">全口座</option>" + selacc

    # display stats list
    displist = ""
    displist =
      (HtmlUtil.fmtStatsList(session[UPDRET])).to_s unless session[UPDRET].nil?

    form = Pathname("view/Stat.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def update session,args
    session[UPD_Y] = (args[0][SELYEAR][0]).to_i
    session[UPD_M] = (args[0][SELMONTH][0]).to_i
    session[UPD_O] = args[0][SELOWNER][0]
    session[UPD_A] = args[0][SELACC][0]
    act = args[0]["action"][0]

    upderr = Array.new

    if act=="display" or act=="stats"
      isSucUpd = true
      if act=="stats"
        # update
        updret = Statistic.updStats(session[UPD_Y],session[UPD_M])
        unless updret[:retval]
          upderr.concat(updret[:err])
          isSucUpd = false
        end
      end
      # show statistics
      if isSucUpd
        getret =
          Statistic.getStats(session[UPD_Y],session[UPD_M],
                             session[UPD_O],session[UPD_A])
        if not getret[:err].nil?
          upderr.push(getret[:err])
        else
          session[UPDRET] = getret[:retval]
        end
      end
    end
    session[UPDERR] = upderr unless upderr.empty?

    return "", true, (HtmlUtil.getStatUrl)
  end
end
