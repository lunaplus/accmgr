# encoding: utf-8
# Loan Controller
require_relative '../util/HtmlUtil'
require_relative '../model/Specification'
require 'erb'
require 'pathname'

class LoanController
  UPDERR = "Loan.updErr"

  CHKDONE = "chkdone"
  HIDMAXSID = "hidMaxSid"
  SELYEAR = "selyear"
  SELMONTH = "selmonth"

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getLoanUrl)

    updUrl = HtmlUtil.getLoanUrl("update")
    srchUrl = HtmlUtil.getLoanUrl

    y = args[0][SELYEAR][0].to_i
    yy = (y==0 ? y : y - Time.now.year)
    m = args[0][SELMONTH][0].to_i
    m = Time.now.month if m<1 or 12<m
    selyear = HtmlUtil.createYearSel yy,-5,1
    selmonth = HtmlUtil.createMonthSel m,true

    chkDone = (args[0][CHKDONE][0] != "on") # true: not done, false: done
    srch = Specification.listLoaning chkDone,y,m
    searchresult = HtmlUtil.fmtLoaningList(srch[:retval])
    js = ""
    if chkDone==false
      js = <<-JS
        <script>
          document.getElementById('#{CHKDONE}').checked=true;
        </script>
      JS
    end  

    maxsid = 0
    if chkDone==true
      lists = srch[:retval][:lists]
      lists.each do |elm|
        maxsid = elm[:sid] if maxsid<elm[:sid]
      end
    end
    
    errorstr = ""
    errorstr = session[UPDERR] unless session[UPDERR].nil?
    errorstr += ", " + srch[:err] unless srch[:err].nil?
    session[UPDERR] = nil

    form =
      Pathname("view/Loan.html.erb").read(:encoding => Encoding::UTF_8) + js
    return (ERB.new(form).result(binding)), false, ""
  end

  def update session,args
    maxsid = args[0][HIDMAXSID][0].to_i

    if maxsid>0
      rslt = Specification.updLoanings maxsid
      unless rslt[:retval]
        if rslt[:err].nil?
          session[UPDERR] = "対象件数が0件でした。"
        else
          session[UPDERR] = rslt[:err]
        end
      else
        session[UPDERR] = "正常に清算更新されました。"
      end
    else
      session[UPDERR] = "清算済を表示にチェックが入っているか、対象が0件です。"
    end

    return "", true, HtmlUtil.getLoanUrl
  end
end
