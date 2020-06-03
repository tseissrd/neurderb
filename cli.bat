@set pwd=%cd%
@cd src
@ruby nrbClient.rb %1 %2
@cd %pwd%