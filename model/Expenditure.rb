# encoding: utf-8
# Expenditures model (費目)
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

=begin
create table expenditures (
       EID bigint auto_increment primary key,
       name varchar(20),
       classify	bit(1),
       freeze bit(1) not null default b'0',
       sorts int
);
-- classify : b'1'=>in, b'0'=>out, null=>move
-- freeze : b'1'=>freezed, b'0'=>normal
=end

class Expenditure < ModelMaster
  C_IN = 1
  C_OUT = 2
  C_MOVE = 3
  C_DBIN = 1
  C_DBOUT = 0

  C_FREEZED = 1
  C_NOFREEZED = 0
  C_DBFRZ = 1
  C_DBNOM = 0

  C_MAXNAMELEN = 20

  C_EXPNAMEERR = "費目名は20文字以内で指定してください。"
  C_CLASSIFYERR = "収支区分は1(in),2(out),3(move)のいずれかにて" +
                  "指定してください。"
  C_EIDERR = "費目IDを指定してください。"
  C_FREEZEERR = "非表示フラグは1(非表示),0(表示)のいずれかにて" +
                "指定してください。"
  C_SORTERR = "並び順は整数で指定してください。"

  def self.clsfyToDbVal(clsfy)
    iserr = false

    case clsfy
    when C_IN then
      cls = "b'" + C_DBIN.to_s + "'"
    when C_OUT then
      cls = "b'" + C_DBOUT.to_s + "'"
    when C_MOVE then
      cls = "null"
    else
      cls = "収支区分に予期せぬ値が指定されました。"
      iserr = true
    end

    return {:retval => cls, :err => iserr}
  end
  private_class_method :clsfyToDbVal

  def self.frzToDbVal(frz)
    iserr = false

    case frz
    when C_FREEZED then
      retfrz = "b'" + C_DBFRZ.to_s + "'"
    when C_NOFREEZED then
      retfrz = "b'" + C_DBNOM.to_s + "'"
    else
      retfrz = "非表示フラグに予期せぬ値が指定されました。"
      iserr = true
    end

    return {:retval => retfrz, :err => iserr}
  end
  private_class_method :frzToDbVal

  def self.ins(expName, clsfy, frz, sorts)
    retval = false
    reterr = nil
    begin
      # input check
      if expName.nil? or (not expName.instance_of?(String)) or
        ## expName
        expName.length < 1 or expName.length > C_MAXNAMELEN
        reterr = C_EXPNAMEERR
      elsif (not sorts.is_a?(Integer))
        ## sorts
        reterr = C_SORTERR
      elsif (not clsfy.is_a?(Integer)) or clsfy < C_IN or clsfy > C_MOVE
        ## clsfy_1
        reterr = C_CLASSIFYERR
      else
        ## clsfy_2
        tmpcls = clsfyToDbVal(clsfy)
        if tmpcls[:err]
          raise Exception.new(tmpcls[:retval])
        else
          cls = tmpcls[:retval]
        end
        ## frz_1
        if (not frz.is_a?(Integer)) or frz < C_NOFREEZED or frz > C_FREEZED
          reterr = C_FREEZEERR
        else
          ## frz_2
          tmpfrz = frzToDbVal(frz)
          if tmpfrz[:err]
            raise Exception.new(tmpfrz[:retval])
          else
            frzs = tmpfrz[:retval]
          end
          # insert data
          mysqlClient = getMysqlClient
          enEsc = mysqlClient.escape(expName)
          queryStr = <<-SQL
            insert into expenditures(name, classify, freeze, sorts)
                   values('#{enEsc}', #{cls}, #{frzs}, #{sorts.to_s})
          SQL
          mysqlClient.query(queryStr)
          retval = (mysqlClient.affected_rows > 0)
        end
      end
    rescue Mysql2::Error => e
      reterr = e.message
    rescue Exception => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end

  def self.upd(eid, expName=nil, clsfy=nil, frz=nil, sorts=nil)
    retval = false
    reterr = nil
    begin
      # input check
      if eid.nil? or (not eid.is_a?(Integer))
        ## EID (Primary Key)
        reterr = C_EIDERR
      elsif expName.nil? and clsfy.nil? and frz.nil? and sorts.nil?
        ## all attributes nil
        reterr = "費目名、収支区分、表示フラグ、並び順のうち、" +
                 "いずれか１つ以上指定してください。"
      elsif (not expName.nil?) and
            ( (not expName.instance_of?(String)) or
              expName.length < 1 or expName.length > C_MAXNAMELEN
            )
        ## expName
        reterr = C_EXPNAMEERR
      elsif (not clsfy.nil?) and
            ( (not clsfy.is_a?(Integer)) or clsfy < C_IN or clsfy > C_MOVE )
        ## clsfy_1
        reterr = C_CLASSIFYERR
      elsif (not frz.nil?) and
            ( (not frz.is_a?(Integer)) or
              frz > C_FREEZED or frz < C_NOFREEZED
            )
        ## frz_1
        reterr = C_FREEZEERR
      elsif (not sorts.nil?) and (not sorts.is_a?(Integer))
        ## sorts
        reterr = C_SORTERR
      else
        ## clsfy_2
        unless clsfy.nil?
          tmpcls = clsfyToDbVal(clsfy)
          if tmpcls[:err]
            raise Exception.new(tmpcls[:retval])
          else
            cls = tmpcls[:retval]
          end
        else
          cls = nil
        end
        ## frz_2
        unless frz.nil?
          tmpfrz = frzToDbVal(frz)
          if tmpfrz[:err]
            raise Exception.new(tmpfrz[:retval])
          else
            frzs = tmpfrz[:retval]
          end
        else
          frzs = nil
        end
        # update data
        mysqlClient = getMysqlClient
        enEsc = (expName.nil? ? nil : mysqlClient.escape(expName))
        queryStr = " update expenditures set "
        tmpArr = Array.new
        tmpArr.push(" name = '#{enEsc}' ") unless expName.nil?
        tmpArr.push(" classify = #{cls} ") unless clsfy.nil?
        tmpArr.push(" freeze = #{frzs} ") unless frzs.nil?
        tmpArr.push(" sorts = #{sorts.to_s} ") unless sorts.nil?
        queryStr += tmpArr.join(",")
        queryStr += " where EID = #{eid.to_s}"

        mysqlClient.query(queryStr)
        retval = (mysqlClient.affected_rows > 0)
      end
    rescue Mysql2::Error => e
      reterr = e.message
    rescue Exception => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end

  def self.del(eid)
    retval = false
    reterr = nil
    begin
      if eid.nil? or (not eid.is_a?(Integer))
        reterr = C_EIDERR
      else
        queryStr = " delete from expenditures where EID = #{eid.to_s} "
        mysqlClient = getMysqlClient
        mysqlClient.query(queryStr)

        retval = (mysqlClient.affected_rows > 0)
      end
    rescue Mysql2::Error => e
      reterr = e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
    return {:retval => retval, :err => reterr}
  end

  def self.list (clsfy=nil, nofrz=false, sorts=false)
    retval = Array.new
    reterr = nil

    tmpcls = (clsfy.nil? ? {:err => false} : clsfyToDbVal(clsfy))
    unless tmpcls[:err]
      queryStr =
        " select EID, name, classify+0 as cls, freeze+0 as frz, sorts " +
        "   from expenditures "

      whereArr = Array.new
      whereArr.push(" freeze <> #{nofrz.to_s} ") if nofrz
      unless clsfy.nil?
        clsfyWhere = " classify "
        if clsfy == C_MOVE
          clsfyWhere += " is " + tmpcls[:retval]
        else
          clsfyWhere += " = " + tmpcls[:retval]
        end
        whereArr.push clsfyWhere
      end
      if whereArr.size > 0
        queryStr += " where " + (whereArr.join(" and ")) + " "
      end
      
      queryStr += " order by classify desc, "
      queryStr += " sorts, " if sorts
      queryStr += " EID "
      begin
        mysqlClient = getMysqlClient
        rsltSet = mysqlClient.query(queryStr)
        
        rsltSet.each do |row|
          ## classify
          case row["cls"]
          when C_DBIN
            tmpcls = C_IN
          when C_DBOUT
            tmpcls = C_OUT
          when nil
            tmpcls = C_MOVE
          else
            raise Exception.new("classifyが想定外です。 / " + row["cls"].to_s)
          end
          ## freeze
          case row["frz"]
          when C_DBFRZ
            tmpfrz = C_FREEZED
          when C_DBNOM
            tmpfrz = C_NOFREEZED
          else
            raise Exception.new("freezeが想定外です。 / " + row["frz"].to_s)
          end
          # retval
          retval.push({:eid => row["EID"], :name => row["name"],
                       :cls => tmpcls, :freeze => tmpfrz,
                       :sorts => row["sorts"]
                      })
        end
      rescue Mysql2::Error => e
        reterr = e.message
      rescue Exception => e
        reterr = e.message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end
    return {:retval => retval, :err => reterr}
  end

  def self.isExist?(eid)
    retval = false

    if eid.is_a?(Integer)
      begin
        mysqlClient = getMysqlClient
        queryStr = "select 1 from expenditures where EID = #{eid.to_s}"
        rsltset = mysqlClient.query(queryStr)

        retval = (rsltset.size > 0)
      rescue Mysql2::Error => e
        # no return error message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end

    return retval
  end

  def self.foundByName?(name)
    retval = false

    if name.is_a?(String)
      begin
        mysqlClient = getMysqlClient
        queryStr = "select 1 from expenditures where name = '#{name}'"
        rsltset = mysqlClient.query(queryStr)
        
        retval = (rsltset.size>0)
      rescue Mysql2::Error => e
      # no return error message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    end

    return retval
  end

  def self.getEidByName(name, clsfy)
    retval = nil
    reterr = nil

    if name.is_a?(String)
      begin
        mysqlClient = getMysqlClient
        queryStr = "select eid from expenditures where name = '#{name}'"
        unless clsfy.nil?
          if clsfy == C_MOVE
            queryStr += " and classify is " + clsfyToDbVal(clsfy)[:retval]
          else
            queryStr += " and classify = " + clsfyToDbVal(clsfy)[:retval]
          end
        end
        rsltset = mysqlClient.query(queryStr)
        
        if (rsltset.size == 1)
          rsltset.each do |row|
            retval = row["eid"]
          end
        else
          reterr = "同名、同種の費目が複数存在するため、" +
                   "対象を特定できません"
        end
      rescue Mysql2::Error => e
        reterr = e.message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end
    else
      reterr = "引数には文字列(費目名)をセットしてください。"
    end

    return { :retval => retval, :reterr => reterr }
  end

  def self.isAppCls(name, i_o_m)
    retval = false

    if name.is_a?(String) and i_o_m.is_a?(String)
      queryStr =
        " select 1 from expenditures where name = '#{name}' and classify "

      case i_o_m
      when "in" then
        queryStr += " = " + (clsfyToDbVal(C_IN)[:retval])
      when "out" then
        queryStr += " = " + (clsfyToDbVal(C_OUT)[:retval])
      when "move" then
        queryStr += " is " + (clsfyToDbVal(C_MOVE)[:retval])
      else
        # NOOP (goto Mysql2::Error after exec query)
      end
        
      begin
        mysqlClient = getMysqlClient
        rsltset = mysqlClient.query(queryStr)

        retval = (rsltset.size>0)
      rescue Mysql2::Error => e
      # no return error message
      ensure
        mysqlClient.close unless mysqlClient.nil?
      end      
    end

    return retval
  end
  
end
