# encoding: utf-8
# Expenditure Controller
require_relative '../util/HtmlUtil'
require 'erb'
require 'pathname'
require_relative '../model/Account'

class ExpenditureController
  UPDERR = "EXPMGRUPDERR"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getExpUrl)

    actionUrl = HtmlUtil.getExpUrl("update")

    errorstr = session[UPDERR]
    session[UPDERR] = nil

    exptbllist = HtmlUtil.expTblList "trid","tdid"
    
    form = Pathname("view/Exp.html.erb")
      .read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def update session,args
    chkEdits = args[0][HtmlUtil::CHKEDIT]
    eids = args[0][HtmlUtil::HIDEID]
    names = args[0][HtmlUtil::TXTNM]
    clsfys = args[0][HtmlUtil::SELCLSFY]

    errstr = ""

    0.upto(chkEdits.size-1) do |i|
      if eids[i].empty?
        ret = Expenditure.ins(names[i], clsfys[i].to_i)
      else
        ret = Expenditure.upd(eids[i].to_i, names[i], clsfys[i].to_i)
      end

      errstr += ret[:err].join(",") if (not ret[:err].nil?)
    end

    session[UPDERR] = errstr unless errstr.empty?

    return "", true, (HtmlUtil.getExpUrl)
  end
end
