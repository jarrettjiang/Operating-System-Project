code mkdir

  function main()

      var rv: int

      if cmdArgs == null
         Print ("usage: mkdir dirname\n")
	 Sys_Exit(1)
      endIf

      if cmdArgs arraySize != 2 
         Print ("usage: ")
	 Print (cmdArgs[0])
	 Print (" dirname\n")
	 Sys_Exit(1)
      endIf

      rv = Sys_Mkdir (cmdArgs[1])

      if rv < 0
          Print (cmdArgs[1])
	  Print (": could not make the directory.\n")
	  Sys_Exit(1)
      endIf
      Sys_Exit(0)
    endFunction

endCode
