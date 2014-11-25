code ln

  function main()

      var rv: int

      if cmdArgs == null
         Print ("usage: ln oldname newname\n")
	 Sys_Exit(1)
      endIf

      if cmdArgs arraySize != 3 
         Print ("usage: ")
	 Print (cmdArgs[0])
	 Print (" oldname newname\n")
	 Sys_Exit(1)
      endIf

      rv = Sys_Link (cmdArgs[1], cmdArgs[2])

      if rv < 0
          Print (cmdArgs[2])
	  Print (": could not link\n")
	  Sys_Exit(1)
      endIf
      Sys_Exit(0)

    endFunction
endCode
