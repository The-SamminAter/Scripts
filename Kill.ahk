#IfWinNotActive, ahk_exe explorer.exe
!Q::
    WinGet, win_pid, PID, A
    Run, taskkill /f /pid %win_pid%
return
#IfWinNotActive