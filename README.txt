# Set-Scheduled-Task
An old script that sets a scheduled task on a remote Windows system

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
