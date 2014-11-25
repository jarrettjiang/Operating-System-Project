-- Simple "grep program" that really doesn't understand
-- regular expressions
--
--   grep string [files...]
--       print lines containing string
--
--   grep -v string [files ...]
--       print lines that don't contain string
--
--   Phil Nelson,  May 2013
--

code grep

  var optV: bool = false
      retVal: int = 1

  function main ()
    var ix: int = 1
        pat: int
	fd: int

    if cmdArgs == null
       -- Yell ... need at least something to grep for!
       Print ("grep: no arguments\n")
       Sys_Exit(1)
    endIf

    -- Process command line args
    while ix < cmdArgs arraySize && cmdArgs[ix][0] == '-'
      switch cmdArgs[ix][1]
	case 'v':
	  optV = true
	  break
	default:
          Print ("Unknown switch: ")
	  Print (cmdArgs[ix])
	  Print ("\n")
	  Sys_Exit(1)
      endSwitch
      ix = ix + 1
    endWhile

    if ix == cmdArgs arraySize
      Print ("grep: missing pattern\n")
      Sys_Exit(1)
    endIf

    -- Process files or input
    pat = ix
    ix = ix + 1
    if ix == cmdArgs arraySize  
       -- Process standard in
       do_grep (0, cmdArgs[pat])
    else
       while ix < cmdArgs arraySize
         fd = Sys_Open (cmdArgs[ix],O_READ,0)
         ix = ix + 1
	 do_grep (fd, cmdArgs[pat])
       endWhile
    endIf

    Sys_Exit (retVal)
    
  endFunction

  function do_grep (fd: int, pat: String)
    var buff: array [ 1024 ] of char
        ix, iy: int
	match: bool

	patSize: int = pat arraySize

       buff = new array [ 1024] of char { 1024 of ' ' }

       while dReadLine (fd, &buff)
          ix = 0
	  match = false

	  while ix < buff arraySize - patSize && !match
	     if buff[ix] == '\n'
	        break
	     endIf

	     if buff[ix] == pat[0] && buff[ix+patSize-1] == pat[patSize-1]
	        iy = 0
		while iy < patSize  && buff[ix+iy] == pat[iy]
		    iy = iy + 1
		endWhile
		match = iy == patSize
	     endIf
	     ix = ix + 1
	  endWhile

	  if match != optV
	     PrintToNL (&buff)
	     retVal = 0
	  endIf

       endWhile

    endFunction

  function PrintToNL (str: String)
     var ix: int = 0

     while ix < str arraySize && str[ix] != '\n'
        ix = ix + 1
     endWhile

     if ix < str arraySize 
        ix = ix + 1
     endIf

     if ix != Sys_Write (1, &str[0], ix)
        Print ("**** Write Error")
	Sys_Exit(1)
     endIf

    endFunction

endCode
