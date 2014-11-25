code rm

  function main ()
    -- this is a simplified version of the "rm" program 
    var ix, rv: int
        retVal: int = 0

    if cmdArgs == null || cmdArgs arraySize < 2
       Print ("Usage: rm file [file ...]\n")
       Sys_Exit(1)
    endIf

    -- remove the list of files
    for ix = 1 to cmdArgs arraySize -1
        rv = Sys_Unlink (cmdArgs[ix])
	if rv < 0
	    Print ("rm: ")
	    Print (cmdArgs[ix])
	    Print (": file not removed\n")
	    retVal = 1
	endIf
    endFor
    Sys_Exit (retVal)

  endFunction

endCode
