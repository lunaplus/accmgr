# encoding: utf-8
# Specification Controller
require_relative '../util/HtmlUtil'
require_relative '../model/Specification'
require 'erb'
require 'pathname'

class SpecController
  UPDERR = "Spec.updErr"
  UPDRST = "Spec.updResult"
  UPD_Y = "Spec.year"
  UPD_M = "Spec.month"
  UPD_O = "Spec.owner"
  UPD_A = "Spec.account"
  UPD_E = "Spec.expenditure"

  SELYEAR = "selyear"
  SELMONTH = "selmonth"
  SELOWNER = "selowner"
  SELACC = "selaccount"
  SELEXP = "selexpenditure"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getSpecUrl)

    actionUrl = HtmlUtil.getSpecUrl("update")

    errorstr = ""
    errorstr = session[UPDERR] unless session[UPDERR].nil?
    session[UPDERR] = nil

    y = (session[UPD_Y].nil? or session[UPD_Y]==0 ? 0
         : (session[UPD_Y] - Time.now.year))
    m = (session[UPD_M].nil? ? (Time.now.month) : session[UPD_M])

    msel = (not (m==0 or m==13))
    owner = (session[UPD_O].nil? ? login : session[UPD_O])
    acc = session[UPD_A]
    eid = session[UPD_E]
    session[UPD_Y] = nil
    session[UPD_M] = nil
    session[UPD_O] = nil
    session[UPD_A] = nil
    session[UPD_E] = nil

    # set select box values
    selyear = HtmlUtil.createYearSel y,-5,1
    selmonth = HtmlUtil.createMonthSel m,msel

    selowner = HtmlUtil.getUserSel(owner)
    selowner =
      "<option value=\"\"></option>" + selowner

    selacc = HtmlUtil.accSel(acc.to_i)
    selacc =
      "<option value=\"\"></option>" + selacc

    selexp = HtmlUtil.expSel(nil,(eid.nil? ? nil : eid.to_i))

    searchresult = ""
    searchresult = session[UPDRST] unless session[UPDRST].nil?
    session[UPDRST] = nil

    form = Pathname("view/Spec.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def update session,args
    session[UPD_Y] = (args[0][SELYEAR][0]).to_i
    session[UPD_M] = (args[0][SELMONTH][0]).to_i
    session[UPD_O] = args[0][SELOWNER][0]
    session[UPD_A] = args[0][SELACC][0]
    session[UPD_E] = args[0][SELEXP][0]

    srch =
      Specification.search(session[UPD_Y],session[UPD_M],
                           session[UPD_O],session[UPD_A],
                           session[UPD_E])
    formedsrch = HtmlUtil.fmtSpecList(srch[:retval])

    session[UPDERR] = srch[:err]
    session[UPDRST] = formedsrch

    return "", true, HtmlUtil.getSpecUrl
  end
end
