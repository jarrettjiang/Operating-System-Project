code UserLib

-----------------------------  GetChar  ---------------------------------

  function dGetChar (fd: int) returns char
    --
    -- This function reads a single character from stdin and returns it.
    --
      var c: char
          i: int
      i = Sys_Read (fd, &c, 1)
      if i == 0
        return EOF
      elseIf i < 0
        Print ("Problems in GetChar\n")
	return EOF
      endIf
      return c    
    endFunction

  function GetChar () returns char
     return dGetChar (stdin)
    endFunction


-----------------------------  ReadLine  ---------------------------------

  function ReadLine (line: String) returns bool
    --
    -- This function reads in a line of input and it moves the character into
    -- the commandLine buffer, echoing characters as they are typed.  It will
    -- make sure that a \n goes into the commandLine buffer, even if the
    -- user tries to overflow the buffer.
    --
      var i: int = 0
          ch: char
      while true
        ch = GetChar ()
        if ch == EOF
          if i > 0
	     line[i] = '\n'
	     return true
	  else
	     return false
	  endIf
        elseIf ch == '\n'
          PutChar (ch)
          line [i] = ch
          return true
        elseIf ch == '\b' || ch == '\x7f'  -- cntrl-H or "DEL" char on MAC keyboard
          if i > 0
            Print ("\b \b")
            i = i - 1
          else
            PutChar ('\a')  -- bell/alert
          endIf
        else
          PutChar (ch)
          line [i] = ch
          i = i + 1
        endIf
        if i >= line arraySize -1
          line [i] = '\n'
          PutChar ('\n')
          return true
         endIf
      endWhile
    endFunction


-----------------------------  dReadLine  ---------------------------------

   function dReadLine (fd: int, line: String) returns bool
    --
    -- This function reads in a line of input and it moves the character into
    -- the commandLine buffer NOT echoing characters as they are typed.  It will
    -- make sure that a \n goes into the commandLine buffer, even if the
    -- user tries to overflow the buffer.
    --
      var i: int = 0
          ch: char
      while true
        ch = dGetChar (fd)
        if ch == EOF
          if i > 0
	     line[i] = '\n'
	     return true
	  else
	     return false
	  endIf
        elseIf ch == '\n'
          line [i] = ch
          return true
        else
          line [i] = ch
          i = i + 1
        endIf
        if i >= line arraySize -1
          line [i] = '\n'
          return true
         endIf
      endWhile
     endFunction


-----------------------------  PutChar  ---------------------------------

  function dPutChar (fd: int, c: char)
    --
    -- This function writes a single character to stdout.
    --
      var i: int
      i = Sys_Write (fd, &c, 1)
      if i < 0
        Print ("Problems in PutChar\n")
      endIf

    endFunction

  function PutChar (c: char)
     dPutChar (stdout, c)
    endFunction


----------------------------- dPrint  ---------------------------------

  function dPrint (fd: int, str: String)
    --
    -- This function is passed a string.  It prints it to stdout.
    --
      var i: int
      i = Sys_Write (fd, &str[0], str arraySize)     
    endFunction

----------------------------- Print  ---------------------------------

  function Print (str: String)
    --
    -- This function is passed a string.  It prints it to stdout.
    --
      var i: int
      i = Sys_Write (stdout, &str[0], str arraySize)     
    endFunction


-----------------------------  dPrintInt  ------------------------------

  function dPrintInt (fd: int, num: int)
    var
      chars: array [ 14 ] of char

      -- Conver to chars ...
      chars = new array [14] of char { 14 of ' '}
      IntToString (num, &chars)

      -- Print it
      dPrint (fd, &chars)

    endFunction

-----------------------------  PrintInt  ------------------------------

  function PrintInt (num: int)
      dPrintInt (stdout, num)
    endFunction

---------------------------- StringToInt ---------------------------

  function StringToInt (str: String) returns int

     var ix: int
         retval: int
         neg: bool

     if str[0] == '-'
        neg = true
        ix = 1
     else
        neg = false
        ix = 0
     endIf
	
     retval = 0
     while ix < str arraySize && (str[ix] >= '0') && (str[ix] <= '9')
        retval = retval * 10 - '0' + str[ix]
        ix = ix + 1
     endWhile

     if neg
       return -retval
     else
       return retval
     endIf

  endFunction

---------------------------- IntToString ---------------------------

  function IntToString (val: int, str: String)
    var ix: int
       num: int
        sx: int
       neg: bool
      chars: array [ 12 ] of char
 
       -- Special case of 0
      if val == 0
	 str[0] = '0'
	 *(str asPtrTo int) = 1
	 return
      endIf

    -- Check for negative numbers
      if val < 0
        neg = true
	val = -val
      else
        neg = false
      endIf

      chars = new array of char { 12 of ' ' }
      ix = 0
      num = val
      while num > 0
         chars[ix] = intToChar('0' + num %10)
	 num = num / 10
	 ix = ix + 1
      endWhile

     -- Set the length
      if neg 
        *(str asPtrTo int) = ix
	str[0] = '-'
        sx = 1
      else
        *(str asPtrTo int) = ix
	sx = 0
      endIf
      while ix > 0
	 ix = ix -1
         str[sx] = chars[ix]
	 sx = sx + 1
      endWhile

    endFunction


endCode
