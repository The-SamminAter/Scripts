; Credit to 0x464e on Stack Overflow: https://stackoverflow.com/questions/60080578/ahk-find-pid-of-explorer-exe/60080947#60080947
#IfWinNotActive, ahk_exe explorer.exe
!Q::
    WinGet, win_pid, PID, A
    Run, taskkill /f /pid %win_pid%
return
#IfWinNotActive
