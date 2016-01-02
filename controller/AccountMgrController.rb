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
    chkEdits = args[0][HtmlUtil::CHKEDIT]
    aids = args[0][HtmlUtil::HIDAID]
    names = args[0][HtmlUtil::TXTNM]
    iscards = args[0][HtmlUtil::CHKISCD]
    uids = args[0][HtmlUtil::SELUID]
    balances = args[0][HtmlUtil::TXTBL]

    errstr = ""

    0.upto(chkEdits.size-1) do |i|
      if aids[i].empty?
        ret = Account.ins(names[i], (iscards[i]=="on"),
                          uids[i], (balances[i].gsub(/,/, '').to_i))
      else
        ret = Account.upd(aids[i].to_i, names[i], (iscards[i]=="on"),
                          uids[i], (balances[i].gsub(/,/, '').to_i))
      end

      errstr += ret[:err].join(",") if (not ret[:err].nil?)
    end

    session[UPDERR] = errstr unless errstr.empty?

    return "", true, (HtmlUtil.getAccUrl)
  end
end
