-- Simple wc program ... no options
--
--
--   Phil Nelson,  May 2013
--

code wc

  var
	optC: bool = false
        optL: bool = false
	optW: bool = false
	hadArgs: bool = false

  function main ()
    var ix: int = 1
	fd: int
        retVal: int = 0

    if cmdArgs == null 
       Count (0, "stdin")
       Sys_Exit(0)
    endIf

    -- Process command line args
    while ix < cmdArgs arraySize && cmdArgs[ix][0] == '-'
      switch cmdArgs[ix][1]
	case 'c':
	  optC = true
	  break
	case 'l':
	  optL = true
	  break
	case 'w':
	  optW = true
	  break
	default:
          Print ("Unknown switch: ")
	  Print (cmdArgs[ix])
	  Print ("\n")
	  Sys_Exit(1)
      endSwitch
      hadArgs = true
      ix = ix + 1
    endWhile

    if ix == cmdArgs arraySize
      Count (0, "stdin")
      Sys_Exit(0)
    endIf

    -- Process files or input
    if ix == cmdArgs arraySize  
       -- Process standard in
       Count (0, cmdArgs[ix])
    else
       while ix < cmdArgs arraySize
         fd = Sys_Open (cmdArgs[ix],O_READ,0)
         if fd < 0
            Print ("wc: ")
            Print (cmdArgs[ix])
            Print (": Could not open.\n")
            ix = ix + 1
	    retVal = 1
            continue
         endIf
	 Count (fd, cmdArgs[ix])
         ix = ix + 1
       endWhile
    endIf
    Sys_Exit(retVal)

  endFunction

  function Count (fd: int, name: String)
    var 
        chars: int = 0
	lines: int = 0
	words: int = 0

        inWord: bool = false	
	ch: char

	ch = dGetChar(fd)
	-- if (fd == 0 && ch != EOF) PutChar (ch) endIf
	while ch != EOF
	   chars = chars + 1
	   switch ch
	     case '\n':
	       lines = lines + 1
	       if inWord
	         inWord = false
	       endIf
	       break
	     case ' ':
	       inWord = false
	       break
	     default:
	       if !inWord
	          inWord = true
		  words = words + 1
               endIf
	   endSwitch
	   ch = dGetChar(fd)
	   -- if (fd == 0 && ch != EOF) PutChar (ch) endIf
        endWhile

	if hadArgs
	   if optL
	      PrintInt (lines)
	      Print ("  ")
	   endIf
	   if optW
	      PrintInt (words)
	      Print ("  ")
	   endIf
	   if optC
	      PrintInt (chars)
	      Print ("  ")
	   endIf
	else
	   PrintInt (lines)
	   Print ("  ")
	   PrintInt (words)
	   Print ("  ")
	   PrintInt (chars)
	   Print ("  ")
	endIf
	Print (name)
	Print ("\n")

    endFunction

endCode
