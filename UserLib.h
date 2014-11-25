--
--  User Library routines ....
--
--     Phil Nelson, Spring 2013
--
--     I/O and other routines using system calls that
--     are useful routines in many user-land programs.

header UserLib

  uses UserSystem

  const stdin  = 0
        stdout = 1
        EOF = '\xFF'

  functions

    ReadLine ( line: String) returns bool
    dReadLine (fd:int, line: String) returns bool

    GetChar () returns char
    dGetChar (fd: int) returns char

    PutChar (c: char)
    dPutChar (fd: int, c: char)

    Print (str: String)
    dPrint (fd: int, str: String)

    PrintInt (num: int)
    dPrintInt (fd: int, num: int)
    
    StringToInt (str: String) returns int
    IntToString (val: int str: String)
    

endHeader

