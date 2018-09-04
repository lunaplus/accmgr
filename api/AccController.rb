# encoding: utf-8
# Csv Controller
require_relative '../util/HtmlUtil'
require_relative '../model/Account'
require 'erb'
require 'pathname'
require 'json'

class AccController

  def amount session,body,args
    aid = args[0]["aid"][0]

    if aid.nil? or "" == aid
      retval = JSON.generate({:aid => aid,
                              :err => "aid is empty"})
    else
      rethash = Account.getBalance aid
      if rethash[:err].nil?
        hash = {:aid => aid, :amount => rethash[:retval][:balance],
                :name => rethash[:retval][:name]}
      else
        hash = {:aid => aid, :err => rethash[:err]}
      end
      
      retval = JSON.generate(hash)
    end

    retopt = HtmlUtil.getJsonHeader
    return retopt,retval
  end

end
