code echoargs

  function main()
    var ix: int

      if cmdArgs == null
         Print ("No Arguments provided.\n")
	 Sys_Exit(1)
      else
         for ix = 0 to cmdArgs arraySize - 1
	    Print ("arg[")
	    PrintInt (ix)
	    Print ("] is '")
	    Print (cmdArgs[ix])	
	    Print ("'\n")
         endFor
      endIf

      Sys_Exit (0)

    endFunction

endCode
