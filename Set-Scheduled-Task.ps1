Param(
    [Switch]$Console = $false,              #--[ Set to true to enable local console result display. Defaults to false ]--
    [Switch]$Debug = $False,                #--[ Set to true to only send results to debug email address. Default to false ]--
    [Switch]$Enable = $False,               #--[ Set to true to only send results to debug email address. Default to false ]--
    $Computer = "",                         #--[ Use to target once PC. Forces single source if detected ]--
    $Source = "AD",                         #--[ Where to get target list. Defaults to Ad ]--
    $Mode = "disable",                      #--[ Run mode. Defaults to disable ]--
    $RndMin = 1,                            #--[ Task minute randomizer start. Defaults to 1 ]--
    $RndMax = 59                            #--[ Task minute randomizer end. Defaults to 59 ]--
)

<#==============================================================================
         File Name : Set-Scheduled-Task.ps1
   Original Author : Kenneth C. Mazie (kcmjr AT kcmjr.com)
                   :
       Description : Creates a new (or over-writes existing) scheduled task on target systems.
                   :
             Notes : Normal operation is with no command line options. If "debug" is used as an argument
                   : debugging level 1 is enabled. Requires PowerShell AD module or will exit.
                   : - This script will batch apply a scheduled task to the targeted PC with settings from the
                   : variables section below.
                   : - Modify items in the variables section to suit your site and department/facility codes.
                   : - As written the script performs NO actions until the "$Enable" variable is set to "$True"
                   : via the command line.
                   : - Test thoroughly on a single PC before use. VERIFY IT REBOOTS AND DOESN'T JUST HANG.
                   : - Targeting is via AD or text file. You can use Active Directory and filtering to
                   : identify the systems to process, or use a flat text file named "targets.txt" located in
                   : the same folder as this script.
                   : - Please use PowerShell v5 or newer or the script will yell at you.
                   : - Screen output is all that is provided, to output to a text file you must redirect
                   : the write-host commands.
                   : - To execute this script open a PowerShell window using an account with local
                   : administrator access to the targeted PCs. Change to the script folder. Call the script thus:
                   : "./set-scheduled-task.ps1 -option1 -option2 etc."
                   :
         Arguments : Command line options for testing:
                   : - "-console $true" Will enable local console echo
                   : - "-enable $true" Will enable the script.
                   : - "-debug" Not used
                   : - "-mode" Options include "set","delete", and "disable". Defaults to "set"
                   : - "-source" Tells the script where to get the targets from. Options include "AD",
                   : "single", or "file". Defaults to "AD".
                   : - "-computer" Specifies a single target. If used forces single mode.
                   : - "-rndmin" Task start minute randomizer. Defaults to 1
                   : - "-rndmax" Task end minute randomizer. Defaults to 59. Use these two to define the
                   : start/stop window and length.
                   : - These may be used individually or in any combination and in any order.
                   :
          Warnings : None
                   :
             Legal : Public Domain. Modify and redistribute freely. No rights reserved.
                   : SCRIPT PROVIDED "AS IS" WITHOUT WARRANTIES OR GUARANTEES OF
                   : ANY KIND. USE AT YOUR OWN RISK. NO TECHNICAL SUPPORT PROVIDED.
                   :
           Credits : Code snippets and/or ideas came from many sources including but
                   : not limited to the following:
                   :
    Last Update by : Kenneth C. Mazie
   Version History : v1.00 - 08-25-14 - Original
    Change History : v1.01 - 00-00-00 -
                   #>               
   $CurrentVersion = 1.00    <#--[ Denotes current version
                   :
==============================================================================#>
<#PSScriptInfo
.VERSION 1.00
.AUTHOR Kenneth C. Mazie (kcmjr AT kcmjr.com)
.DESCRIPTION
Creates a new scheduled task on target systems. Also can disable or delete existing
tasks that use the same task name.
#>
#===========================[ Initialization ]==================================
Clear-Host
$ErrorActionPreference = "stop"

If ($PSVersionTable.PSVersion.Major -lt 5){  #--[ Force PowerShell v5 (as opposed to using a "requires" tag) ]--
    Write-host `n`n"Please upgrade your PowerShell version to at least v5."`n`n -ForegroundColor Red
    Break
}

Function SendEmail { #--[ Function to send email notification (Not Used Yet) ]--
    #----[ NOTE: Not currently used ]----
    $SMTP = new-object System.Net.Mail.SmtpClient($MailServer)
    $Email = New-Object System.Net.Mail.MailMessage
    $Email.Body = $Message
    $Email.IsBodyHtml = $true
    $Email.To.Add($Recipient)
    $Email.From = $MailFrom 
    $Email.Subject = $Subject
    $SMTP.Send($Email)
    $Email.Dispose()
    $SMTP.Dispose()
}

#--[ Manual Bypass Debugging Options For Testing ]------------------------------------------------
#$Console = $true #--[ Enables local console result display ]--
#$Debug = $true #--[ Forces email to only go to debug user ]--
#$Enable = $true #false #--[ Set to $TRUE to enable task creation ]--
#$Source = "single" #--[ Force a single target ]--
#$Mode = "disable" #--[ Set task mode ]--
#$RndMin = 1 #--[ Task minute randomizer start ]--
#$RndMax = 59 #--[ Task minute randomizer end ]--
#--------------------------------------------------------------------------------------------------

#--[ Variables ]-------------------------------------
$TaskName = "Nightly_Restart"                   #--[ Name of scheduled task ]--
$DeptCodes = @("hr","it","op")                  #--[ Department code(s) to scan (quoted and comma delimited) ]--
$BypassList = @("pc123","pc456","pc789")        #--[ Explicit systems to NOT touch ]--
$SiteCode = "pc*"                               #--[ system type and site code to scan ]--
$TaskHour = "02"                                #--[ Hour of day to run the task ]--

If ($Computer){$Source = "single"}  
If ($Source -eq "single"){  #--[ Target source selection from command line ]--
    $Targets = Get-ADComputer -Filter {Name -like $Computer} | Select -Property Name    #--[ This can be used to load a single, or small list of systemstext file from the script folder ]--
}ElseIf ($Source -eq "file"){
    $Targets = Get-Content $PSSCriptRoot\targets.txt                                     #--[ This can be used to load a text file from the script folder ]--
}Else{
    $Targets = Get-ADComputer -Filter {Name -like $SiteCode} | Select -Property Name     #--[ Will get all systems from AD starting with the sitecode variable ]--
}

#--[ Cycle through targets ]--
If ($Console){Write-host `n'--[ Begin... ]----------------------------------------------' -ForegroundColor Red}
ForEach ($Target in $Targets){
    If ($Target -IsNot [String]){$Target = ($Target.Name | Out-String).Trim()}
    $DeptMatch = $False
    $BypassMatch = $False
    
    #--[ Filters ]--
    If ($Source -ne "single"){
        $DeptCodes | ForEach{
            If ($Target -match $_){
                $DeptMatch = $true
            }
        }
    }Else{
        $DeptMatch = $true
    }    
    $BypassList | ForEach{
        If ($Target -match $_){
            $BypassMatch = $True
        }
    }

    If ($Console){
        Write-host `n'--[ Source :'($Source).PadRight(9," ") -ForegroundColor Yellow -NoNewline
        Write-host ']--------------------------------------' -ForegroundColor Yellow 
        Write-host '--[ Mode :'($Mode).PadRight(8," ") -ForegroundColor Yellow -NoNewline
        Write-host ' ]--------------------------------------' -ForegroundColor Yellow
        Write-host '--[ Base Hour :'($TaskHour).PadRight(8," ") -ForegroundColor Yellow -NoNewline
        Write-host ' ]--------------------------------------' -ForegroundColor Yellow
        Write-host '--[ RND Min :'($RndMin.ToString()).PadRight(8," ") -ForegroundColor Yellow -NoNewline
        Write-host ' ]--------------------------------------' -ForegroundColor Yellow
        Write-host '--[ RND Max :'($RndMax.ToString()).PadRight(8," ") -ForegroundColor Yellow -NoNewline
        Write-host ' ]--------------------------------------' -ForegroundColor Yellow
    }
    If ($DeptMatch){
        If ($Console){Write-host `n'--[ ' -NoNewline -ForegroundColor Yellow}
        If ($Console){Write-host $Target.ToUpper() -NoNewline -ForegroundColor White}
        If ($Console){Write-host ' ]----------------------------------------------------------' -ForegroundColor yellow}
        If ($BypassMatch){    
            If ($Console){Write-host "-- This target is on the BYPASS list..." -ForegroundColor Red}
        }Else{    
            If (Test-Connection -ComputerName $Target -count 1 -ea 0) {  #--[ Validate connection to target ]--
                If ($Console){Write-host "-- Connection test successful..." -ForegroundColor Green}
                $Time = $TaskHour+':'+("{0:d2}" -f (Get-Random -Minimum $RndMin -Maximum $RndMax ))
                #$Time = $TaskHour+":30" #--[ Use to bypass randomizer and set a unique time ]--
                Try{
                    If ($Enable){  #--[ Only process the task if enable is TRUE ]--
                        If ($Mode -eq "set"){
                            If ($Console){Write-host "-- Task time set to"$Time" ..." -ForegroundColor yellow}     
                            IEX -Command 'schtasks /create /f /s $Target /ru "NT AUTHORITY\SYSTEM" /rp "" /sc "daily" /tn $TaskName /tr "shutdown -r -t 0" /st $Time' | Out-Null
                            
                            If ($Console){Write-host "-- Task creation successful..." -ForegroundColor Green}
                            Sleep -Milliseconds 500
                            $Result = IEX -Command 'schtasks /query /s $Target /tn $TaskName'  #--[ Vertify task creation ]--
                            If ($Result -like "*error*"){
                                If ($Console){Write-host "-- Task verification FAILED..." -ForegroundColor Red}
                            }Else{
                                If ($Console){Write-host "-- Task verification successful..." -ForegroundColor Green}
                            }
                        }ElseIf ($Mode -eq "delete"){
                            $Result = IEX -Command 'schtasks /delete /f /s $Target /tn $TaskName ' #| Out-Null
                            Sleep -Milliseconds 500
                            If ($Result -like "*success*"){
                                If ($Console){Write-host "-- Task deletion verified..." -ForegroundColor Green}
                            }Else{
                                If ($Console){Write-host "-- Task deletion FAILED..." -ForegroundColor Red}
                            }                            
                        }ElseIf ($Mode -eq "disable"){
                            IEX -Command 'schtasks /change /disable /s $Target /tn $TaskName ' | Out-Null
                            Sleep -Milliseconds 500
                            $Result = IEX -Command 'schtasks /query /s $Target /tn $TaskName'  #--[ Vertify task disable ]--
                            If ($Result -like "*disabled*"){
                                If ($Console){Write-host "-- Task disable verified..." -ForegroundColor Green}
                            }Else{
                                If ($Console){Write-host "-- Task disable FAILED..." -ForegroundColor Red}
                            }
                        }
                        #--[ Future Enhancement ]--
                        #IEX -Command 'schtasks /create /f /s $Target /ru "NT AUTHORITY\SYSTEM" /rp "" /mo "onstart" /sc "once" /tn "OneTime Reboot Notify" /tr "shutdown -r -t 0" ' | Out-Null
                    }Else{
                        If ($Console){Write-host "-- Task creation is NOT enabled. No actions will be taken..." -ForegroundColor Yellow}
                    }    
                }Catch{
                    If ($Console){Write-host "-- Task processing Failed: " $_.Exception.Message -ForegroundColor Red}
                }    
            }Else{
                If ($Console){Write-host "-- Connection test FAILED..." -ForegroundColor Red}
            }
        }
    }#>
}

If ($Console){Write-host `n'--- COMPLETED ---' -ForegroundColor Red}
#>