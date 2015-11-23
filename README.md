# accmgr
account management app

## deploy

1.create index.cgi from index.cgi.sample (change shebang, GEM_HOME)
2.create model/ModelMaster.rb from model/ModelMaster.rb.samlpe (change DB connecting information)
3.edit httpd.conf with sample/httpd.conf.sample
4.if change root directory, edit util/HtmlUtil.rb (change URLROOT)
