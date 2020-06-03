@set pwd=%cd%
@cd src
@ruby -W0 nrbClient.rb
@cd %pwd%