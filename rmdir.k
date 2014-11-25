code rmdir

  function main ()
    -- this is a simplified version of the "rmdir" program 
    var ix, rv: int
        retVal: int = 0

    if cmdArgs == null || cmdArgs arraySize < 2
       Print ("Usage: rmdir file [file ...]\n")
       Sys_Exit(1)
    endIf

    -- remove the list of files
    for ix = 1 to cmdArgs arraySize -1
        rv = Sys_Rmdir (cmdArgs[ix])
	if rv < 0
	    Print ("rm: ")
	    Print (cmdArgs[ix])
	    Print (": directory not removed\n")
	    retVal = 1
	endIf
    endFor
    Sys_Exit(retVal)
  endFunction

endCode
