@set pwd=%cd%
@cd "%~dp0/src"
ruby nrbCMSend.rb %1
@cd %pwd%