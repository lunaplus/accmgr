# encoding: utf-8
# Csv Controller
require_relative '../util/HtmlUtil'
require_relative '../model/Specification'
require 'erb'
require 'pathname'
require 'csv'

class CsvUploadController
  UPDERR = "CSVULMGRUPDERR"
  UPDDAT = "CSVULMGRUPDDAT"

  CSV_COLNUM = 9

  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getCsvUrl)

    actionUrl = HtmlUtil.getCsvUrl("upload")

    errorstr = session[UPDERR]
    session[UPDERR] = nil

    session[UPDDAT] = nil

    form = Pathname("view/Csv.html.erb")
      .read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def upload session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    menuList = HtmlUtil.getMenuList(HtmlUtil.getCsvUrl)

    actionUrl = HtmlUtil.getCsvUrl("commit")
    returnUrl = HtmlUtil.getCsvUrl("index")

    submitButton = <<-SUBMIT
      <input type="submit" id="submit" name="submit"
             value="更新" />
    SUBMIT
    
    errorstr = session[UPDERR]
    session[UPDERR] = nil
    errarr = Array.new

    session[UPDDAT] = nil

    begin
      # upload data
      csvread = args[0]["csvfile"][0].read.force_encoding(Encoding::UTF_8)
      csvdata = CSV.parse(csvread, { encoding: "UTF-8" })

      csvdata.each_with_index do |row, idx|
        i = idx+1

        if errarr.length > 5
          # エラーが5件を超えたら中断
          errarr.push("(エラーが5件を超えたので処理を中断します)")
          break
        end

        #check input data
        ## 0.column's num
        if CSV_COLNUM != row.length
          errarr.push(i.to_s + "行：列数が" + row.length.to_s +
                      "です。8列で入力してください")
          next
        end
        ## 1.date
        if row[0].nil? or HtmlUtil.fmtStrToDt(row[0]) == nil
          errarr.push(i.to_s + "行1列目：日付形式で入力してください。")
        end
        
        ## 2.out/in/move (text)
        unless (row[1] == "out" or row[1] == "in" or row[1] == "move")
          errarr.push(i.to_s +
                      "行2列目：out/in/moveのいずれかを入力してください。")
        end
        ## 3.expenditure (name, check existance)
        unless (Expenditure.foundByName? row[2])
          errarr.push(i.to_s +
                      "行3列目：存在する費目名を入力してください。")
        end
        
        ## 4.from account (name, check existance)
        unless (row[3].nil? or "".eql?(row[3]) or
                 Account.foundByName?(row[3]))
          errarr.push(i.to_s +
                      "行4列目：存在する口座名(from)を入力してください。")
        end
        ## 5.to account (name, check existance)
        unless (row[4].nil? or "".eql?(row[4]) or
                Account.foundByName?(row[4]))
          errarr.push(i.to_s +
                      "行5列目：存在する口座名(to)を入力してください。")
        end
        ## 6.amounts (number, max n digits)
        #unless ((not row[5].nil?) and row[5].is_a?(Integer))
        unless (row[5] =~ /^[0-9]+$/)
          errarr.push(i.to_s +
                      "行6列目：金額を整数で入力してください。")
        end
        row[5] = row[5].to_i
        
        ## 7.description (text)
        ### no check
        
        ## 8.is loan (n or y)
        unless (row[7] == "y" or row[7] == "n")
          errarr.push(i.to_s +
                      "行8列目：立替払いかどうかをyかnで指定してください。")
        end

        ## 9.payment month
        unless row[8].nil?
          pmonth = row[8].to_i
          unless (1<=pmonth and pmonth<=12)
            errarr.push(i.to_s +
                        "行9列目：カード支払月は1から12の数字で" +
                        "入力してください。")
          end
        end

        ## 2,3.expenditure type and in/out/move
        unless(Expenditure.isAppCls(row[2], row[1]))
          errarr.push(i.to_s +
                      "行2,3番目：費目名とI/Oの種類が一致しません。")
        end

        ## 2,4,5.in/out/move and from/to/both account
        if row[4].nil? or "".eql?(row[3])
          if "in".eql?(row[1]) or "move".eql?(row[1])
            errarr.push(i.to_s +
                        "行2,5番目、収入または口座移動の場合は" +
                        "to口座が必須です。")
          end
        elsif row[3].nil? or "".eql?(row[3])
          if "out".eql?(row[1]) or "move".eql?(row[1])
            errarr.push(i.to_s +
                        "行2,4番目、支出または口座移動の場合は" +
                        "from口座が必須です。")
          end
        end
      end

      if errarr.length > 0
        errorstr = HtmlUtil.arrToHtmlList(errarr, false)
      else
        errorstr = ""
      end
      
      submitButton = "" if (errarr.length > 0 or csvdata.length == 0)
      session[UPDDAT] = csvdata if errarr.length == 0

      confirm_data = csvToTable csvdata

      form = Pathname("view/CsvConfirm.html.erb")
             .read(:encoding => Encoding::UTF_8)
      return (ERB.new(form).result(binding)), false, ""

    rescue CSV::MalformedCSVError
      # CSV読み込みがうまく行かなかった場合
      session[UPDERR] = "CSV形式のファイルをアップロードしてください。"
      return "", true, (HtmlUtil.getCsvUrl)
    rescue => e
      # その他のエラー
      session[UPDERR] = "エラーが発生しました。/ " +
                        e.message +  " / " + e.class.to_s
      return "", true, (HtmlUtil.getCsvUrl)
    end
  end

  def csvToTable parsedCsvdata
    retval = "<div style='height:240px;width:100%;" +
             "overflow:scroll;border-style:inset;'>\n"
    retval += "<table border=1 style='height:100%;" +
              "table-layout:fixed;'>\n"
    retval += <<-HEADER
      <tr>
        <th>日付</th>
        <th>収支区分<br>(in/out/move)</th>
        <th>費目</th>
        <th>口座from</th>
        <th>口座to</th>
        <th>金額</th>
        <th>説明</th>
        <th>立替区分<br>(y/n)</th>
        <th>カード<br>支払い月</th>
      </tr>
HEADER
    parsedCsvdata.each do |row|
      retval += "<tr>\n"
      row.each do |col|
        retval += "  <td>#{col}</td>\n"
      end
      if row.length < CSV_COLNUM
        for i in 1..(CSV_COLNUM-row.length) do
          retval += "  <td></td>\n"
        end
      end
      retval += "</tr>\n"
    end
    retval += "</table></div>\n"

    return retval
  end

  def commit session,args
    # commit upload data and update database
    commit_data = session[UPDDAT]
    session[UPDDAT] = nil

    tmperr = Array.new
    commit_data.each_with_index do |row, idx|
      i = idx + 1

      # 1.date
      wpd = HtmlUtil.fmtStrToDt(row[0])
      # 4.from account
      unless row[3].nil?
        fromhash = Account.getAidByName row[3]
        unless (fromhash[:reterr].nil?)
          tmperr.push(i.to_s + "行目(4)：" + fromhash[:reterr])
          break
        end
        wfrom = fromhash[:retval]
      else
        wfrom = nil
      end

      # 5.to account
      unless row[4].nil?
        tohash = Account.getAidByName row[4]
        unless (tohash[:reterr].nil?)
          tmperr.push(i.to_s + "行目(5)：" + tohash[:reterr])
          break
        end
        pto = tohash[:retval]
      else
        pto = nil
      end

      # 2.in/out/move kinds
      # 3.expenditure(name)
      case row[1]
      when "out"  # payment
        exphash = Expenditure.getEidByName(row[2], Expenditure::C_OUT)
        unless (exphash[:reterr].nil?)
          tmperr.push(i.to_s + "行目(2,3)：" + exphash[:reterr])
          break
        end
        exp = exphash[:retval]
        if wfrom.nil? # row[4]
          tmperr.push(i.to_s + "行目(4)：支出の場合は口座from必須です。")
          break
        end
        pto = nil    # row[5]
      when "in"   # withdraw
        exphash = Expenditure.getEidByName(row[2], Expenditure::C_IN)
        unless (exphash[:reterr].nil?)
          tmperr.push(i.to_s + "行目(2,3)：" + exphash[:reterr])
          break
        end
        exp = exphash[:retval]
        wfrom = nil  # row[4]
        if pto.nil? # row[5]
          tmperr.push(i.to_s + "行目(5)：収入の場合は口座to必須です。")
          break
        end
      when "move" # accounttransfer
        exphash = Expenditure.getEidByName(row[2], Expenditure::C_MOVE)
        unless (exphash[:reterr].nil?)
          tmperr.push(i.to_s + "行目(2,3)：" + exphash[:reterr])
          break
        end
        exp = exphash[:retval]
        if wfrom.nil? or pto.nil? # row[4],row[5]
          tmperr.push(i.to_s + "行目(4,5)：口座移動の場合は" +
                      "口座from/to必須です。")
          break
        end
      end

      # 6.amounts
      amounts = row[5]
      # 7.description
      desc = row[6]
      # 8.is loan(y/n)
      loan = ((row[7].nil? or row[7] == "n") ? nil
              : Specification::LOAN_LOANING)
      # 9.peyment month
      pmonth = (row[8].nil? ? nil : row[8].to_i)

      # update/insert DATABASE
      if tmperr.empty? and (not wfrom.nil?)
        rethash = Account.addBalance(wfrom, -amounts)
        tmperr += [rethash[:err]] unless rethash[:err].nil?
      end
      if tmperr.empty?
        rethash = Specification.ins((HtmlUtil.fmtDtToStr wpd), exp,
                                    wfrom, pto, amounts, pmonth, desc, loan)
        tmperr += rethash[:err] unless rethash[:err].nil?
      end
      if tmperr.empty? and (not pto.nil?)
        rethash = Account.addBalance(pto, amounts)
        tmperr += [rethash[:err]] unless rethash[:err].nil?
      end
    end

    unless tmperr.empty?
      session[UPDERR] =
        (HtmlUtil.arrToHtmlList tmperr,false)
    else
      session[UPDERR] = "正常にCSVアップロード完了しました。"
    end

    return "", true, (HtmlUtil.getCsvUrl)
  end
end
