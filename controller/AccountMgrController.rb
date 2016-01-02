# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require 'erb'
require 'pathname'
require_relative '../model/Account'

class AccountMgrController
  UPDERR = "ACCMGRUPDERR"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getAccUrl)

    actionUrl = HtmlUtil.getAccUrl("update")

    errorstr = session[UPDERR]
    session[UPDERR] = nil

    # acctbllist += Account.list.to_s
    acctbllist = HtmlUtil.accTblList "tr","td"

    form = Pathname("view/AccountMgr.html.erb")
      .read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def update session,args
    session[UPDERR] = args.to_s # DEBUG

    # chkEdits = args[0][CHKEDIT]
    # aids = args[0][HIDAID]

    return "", true, (HtmlUtil.getAccUrl)
  end
end
