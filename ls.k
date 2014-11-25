code ls

  var long: bool = false
      all: bool = false
      dirMode: bool = false

      retVal: int = 0

  function main()
     var ix: int = 1
         ax: int

      -- Check out what we are doing
      if cmdArgs == null 
          listDir (".")
      else
          while ix < cmdArgs arraySize && cmdArgs[ix][0] == '-'
	     for ax = 1 to cmdArgs[ix] arraySize - 1 
	       switch cmdArgs[ix][ax]
	         case 'a':
	           all = true
	           break
	         case 'd':
	           dirMode = true
		   break
	         case 'l':
	           long = true
	           break
	         default:
                   Print ("Unknown switch: ")
		   Print (cmdArgs[ix])
		   Print ("\n")
		   Sys_Exit(1)
	        endSwitch
	     endFor
	     ix = ix + 1
	  endWhile
	  if ix == cmdArgs arraySize
	     listDir (".")
          else 
             while ix < cmdArgs arraySize
	        listFile(cmdArgs[ix], true)
	        ix = ix + 1
             endWhile
	  endIf
      endIf
      Sys_Exit(retVal)

    endFunction

  function listDir(name: String)
    var fd: int
        ent: dirEntry

        fd = Sys_Opendir (name)
	if fd < 0
	   Print ("ls: ") Print (name) Print (": error opening directory.\n")
	   retVal = 1
	   return
	endIf
	if Sys_Chdir (name) < 0
	   Print ("ls: could not change to directory ")
	   Print (name)
	   Print ("\n")
	   retVal = 1
	   --return
	endIf

	while Sys_Readdir (fd, &ent) == 0
	    --Print ("Sys_Readdir: Ent: ") PrintInt(ent.inodeNum)
	    --Print (" ") Print (&ent.name) Print ("\n")
	    if all || ent.name[0] != '.'
	      listFile(&ent.name, false)
	    endIf
        endWhile

    endFunction

 function printModeChar (mode, modeBit: int, modeCh: String)
         if (mode & modeBit) == modeBit
           Print (modeCh)
         else
           Print ("-")
         endIf
    endFunction

 function listFile(name: String, isArg: bool)
    var statBuf: statInfo
        rv: int
        rv = Sys_Stat (name, &statBuf)
     if rv < 0
	 Print ("ls: ") Print (name)
         Print (": error in getting file information.\n")
	 retVal = 1
	 return
      endIf
      if (statBuf.mode & TYPE_DIR) == TYPE_DIR && !dirMode && isArg
	 listDir(name)
	 return
      endIf

      if long
          PrintInt (statBuf.inodeNum)
          Print (" ")
          printModeChar (statBuf.mode, TYPE_DIR, "d")
          printModeChar (statBuf.mode, MODE_READ, "r")
          printModeChar (statBuf.mode, MODE_WRITE, "w")
          printModeChar (statBuf.mode, MODE_EXE, "x")
          Print (" ")
          PrintInt (statBuf.nlinks)
          Print (" ")
          PrintInt (statBuf.fsize)
          Print (" ")
          Print (name)
          Print ("\n")
      else
          Print (name)
	  Print ("\n")
      endIf
  
    endFunction

endCode
