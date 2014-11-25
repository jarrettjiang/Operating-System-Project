code sh

  -----------------------------------
  ----                           ----
  ----    BLITZ Shell Program    ----
  ----                           ----
  -----------------------------------

  const COMMAND_MAX = 255
        MAX_ARGS = 40
	MAX_PIPE = 10

  var commandLine: array [COMMAND_MAX] of char

      -- Command line argument
      args: array [MAX_ARGS] of array [COMMAND_MAX] of char
      argc: int
      argv: array [MAX_ARGS] of ptr to array of char
      exitVal: int

-----------------------------  main  ---------------------------------

  function main ()
    --
    -- This is a simplified version of the shell program found in Unix.
    --

      var
	  -- Script support
	  doPrompt: bool
	  inFd: int
	  rv: int

      -- Initialize the args ...
      commandLine = new array of char { COMMAND_MAX of ' ' }

      -- arg support
      argv = new array of ptr to array of char { MAX_ARGS of null }
      args = new array of array [COMMAND_MAX] of char { MAX_ARGS of commandLine }
      -- Other initialization 
      numEnv = 0  -- should be a better way
      exitVal = 0

      -- script support
      doPrompt = true
      inFd = 0
      if cmdArgs != null
        --Print ("Command args is not null!\n")
        doPrompt = cmdArgs arraySize < 2
        if cmdArgs arraySize > 1
           --Print ("Opening Script ....\n")
           inFd = Sys_Open (cmdArgs[1],O_READ,0)
  	   if inFd < 0
	      Print ("Could not open script file ")
	      Print (cmdArgs[1])
	      Print (".\n")
	      Sys_Exit(1)
	   endIf
        endIf
      endIf

      if doPrompt
        Print ("Welcome to the BLITZ Shell Program.\n")
        Print ("  Type 'exit' to terminate.\n")
        Print ("  Type 'cat help' or 'cat < help' for more info.\n")
	Print ("  If pipes are implemented, type 'cat help | more'.\n")
      endIf

      while true

        -- Print prompt...
	if doPrompt
          Print ("% ")
        endIf

	-- blank out the line
	commandLine = new array of char {COMMAND_MAX of ' ' }

        -- Read in a command line...
	if doPrompt
           if !ReadLine (&commandLine)
	      Print ("Please use 'exit' to terminate the shell.\n")
	   endIf
	else
	   if !dReadLine (inFd, &commandLine)
	      Sys_Exit(0)
	   endIf
	endIf

	rv = ProcessLine (&commandLine,0,1,true)

      endWhile

    endFunction


-----------------------------  FindNextWord  ---------------------------------

  function FindNextWord (cmd:String, start, pos, len: ptr to int,
                         kind: ptr to char)  returns bool
    --
    -- This function looks in the command line buffer and finds the next word.
    -- It updates its parameters.
    --
      var ch: char

      -- Find the next non-blank...
      while *pos < cmd arraySize && cmd[*pos] == ' '
        *pos = *pos + 1
      endWhile

      *start = *pos

      if *pos >= cmd arraySize
         *kind = '\n'
	 return true
      endIf

      -- If it is < or >...
      if *pos < cmd arraySize &&
         (cmd[*pos] == '<' ||
          cmd[*pos] == '>')
        *kind = cmd[*pos]
        *pos = *pos + 1
        *len = 1
        return true
      endIf

      -- If it is \n...
      if *pos < cmd arraySize && cmd[*pos] == '\n'
        *kind = '\n'
        *len = 0
        return true
      endIf

      -- Else it must be a normal word...
      *kind = ' '  -- Normal word
      while *pos < cmd arraySize
        ch = cmd[*pos]
	if ch == '"'
	   *pos = *pos + 1
	   while *pos < cmd arraySize
	      if cmd[*pos] == '"'
	         *pos = *pos + 1
		 break
              else
	         *pos = *pos + 1
              endIf
           endWhile
	   if *pos >= cmd arraySize
	      Print ("sh: mismatched \"\n")
	      return false
	   endIf
        elseIf ch == ' ' ||
           ch == '\n' ||
           ch == '<' ||
           ch == '>'
          break
        endIf
        *pos = *pos + 1
      endWhile
      *len = *pos - *start
      return true
    endFunction


-------------------  expand -----------------------

  function expand (inStr, outStr: String) returns bool
    var inX, outX: int
        inY: int
        cpX: int
        endIn: int
        valP: String
        envName: array [MAX_KEY_LEN] of char 
	numStr: array [14] of char

      *(outStr asPtrTo int) = COMMAND_MAX  -- Start with a full string
      *outStr = new array of char { COMMAND_MAX of ' ' }
      endIn = inStr arraySize -1
      while endIn > 0 && inStr[endIn] == ' ' endIn = endIn - 1 endWhile
      inX = 0
      outX = 0
      while inX < endIn && outX < outStr arraySize
         if inStr[inX] == '$'
	    inX = inX + 1
	    switch inStr[inX]

              case '{':
		inX = inX + 1
		inY = inX
		while inY < endIn && inStr[inY] != '}'
		   inY = inY + 1
                endWhile
		if inY == inStr arraySize
		   Print ("sh: Missing }\n")
		   return false
		endIf
		if inY - inX > MAX_KEY_LEN
		   Print ("sh: Variable name too long\n")
		   return false
		endIf
		*((&envName) asPtrTo int) = inY-inX
		for cpX = 0 to inY - inX -1
		  envName[cpX] = inStr[inX+cpX]
		endFor
	        valP = getEnv(&envName)
	        if valP != null
	           for cpX = 0 to valP arraySize -1
	              outStr[outX] = valP[cpX]
		      outX = outX + 1
	           endFor
                endIf
		inX = inY+1
		break

	      case '?':
		numStr = new array of char { 14 of ' ' }
		IntToString (exitVal, &numStr)
		cpX = 0
		while outX < outStr arraySize && cpX < numStr arraySize
		  outStr[outX] = numStr[cpX]
		  outX = outX + 1
		  cpX = cpX + 1
		endWhile
		inX = inX + 1
		break

              default:
                 outStr[outX] = '$'
		 outX = outX + 1
	    endSwitch
         else
	    outStr[outX] = inStr[inX]
	    outX = outX + 1
	    inX = inX + 1
         endIf
      endWhile
     if outX >= outStr arraySize && inX < endIn
	Print ("sh: expansion too long\n")
        return false
      endIf
      return true
    endFunction

-------------------  processline Helper ------------------

  function closeRedir ( inFd, cinFd, outFd, coutFd: int)
      -- Close any open files
      if cinFd != inFd
	 Sys_Close (cinFd)   
      endIf
      if coutFd != outFd
         Sys_Close (coutFd)
      endIf
    endFunction

----------------------------- ProcessLine ------------------------------

  function ProcessLine (str: String, inFd, outFd: int, wait: bool) returns int

    var   pid, i: int
          rv: int = 0
          cinFd: int = inFd
	  coutFd: int = outFd
          nextPos, len, start: int
          kind: char        -- will be either ' ', '<', '\n', or '>'
          gotInFile, gotOutFile: bool
	  inFile, outFile: array [COMMAND_MAX] of char
	  tempStr :  array [COMMAND_MAX] of char
	  printNL: bool
          nlLoc: int
	  child: int
	  childCnt: int
	  children: array [MAX_PIPE] of int = new array of int { MAX_PIPE of 0}
	  pipeLoc: int
	  pipeFD: array [2] of int = new array of int { 2 of -1 }

      -- Processes a line for the shell
      --Print ("PL: '") Print (str) Print ("'\n")

      -- Initializtions 
      inFile = new array of char { COMMAND_MAX of ' ' }
      outFile = inFile
      tempStr = inFile

      -- Try pipelines!
      nextPos = 0
      nlLoc = StrChr(str, 0, '\n')
      --Print ("nlLoc = ") PrintInt(nlLoc) Print("\n")

      pipeLoc = StrChr(str, nextPos, '|')
      if pipeLoc >= 0 && pipeLoc < nlLoc
         child = 0
      	 childCnt = 0
         while pipeLoc > 0 && childCnt < MAX_PIPE && child >= 0
	    i = Sys_Pipe(&pipeFD)
	    if i != 0
	       Print ("No Pipes left!\n")
	    endIf
	    GetWord (str, &tempStr, nextPos, pipeLoc-nextPos+1)
	    tempStr[pipeLoc-nextPos] = '\n'
	    --Print ("pipe: tempStr is '") Print(&tempStr) Print ("'\n")
	    child = ProcessLine(&tempStr, cinFd, pipeFD[1], false)
	    if child > 0
	       children[childCnt] = child
	       childCnt = childCnt + 1
	    endIf
	    if cinFd != inFd
	        Sys_Close(cinFd)
	    endIf
	    cinFd = pipeFD[0]
	    Sys_Close(pipeFD[1])
	    nextPos = pipeLoc + 1
	    pipeLoc = StrChr(str, nextPos, '|')
	 endWhile

	 if child >= 0
            GetWord (str, &tempStr, nextPos, str arraySize - nextPos)
	    --Print ("pipe final: tempStr is '") Print(&tempStr) Print ("'\n")
	    child = ProcessLine (&tempStr, cinFd, outFd, true)
	    Sys_Close(cinFd)
	 endIf

	 -- Join the children
	 while childCnt > 0
	   childCnt = childCnt -1
	  --Print("Joining: ") PrintInt(children[childCnt]) Print("\n")
	   exitVal = Sys_Join (children[childCnt])
	 endWhile

	 return -1
      endIf

      -- Expansion ....
      if ! expand(str, &tempStr)
         Print ("Expand problem !!!\n")
	 return -1
      else
         StrCopy (str, &tempStr)
      endIf

      -- Parse the arguments    
      gotInFile = false
      gotOutFile = false
      argc = 0

        while true
          if !FindNextWord (str, &start, &nextPos, &len, &kind)
	     return -1
	  endIf
          if kind == '\n'
            break
          elseIf kind == ' '
	    if argc == MAX_ARGS
	      Print ("Too many command line arguments\n")
	      argc = 0
	      exitVal = 1
	      break
            endIf
	    GetWord (str, &args[argc], start, len)
	   -- Print ("got Regular word: ") Print (&args[argc]) Print("\n")
	    argc = argc+1	    
          elseIf kind == '<' && !gotInFile
            if !FindNextWord (str, &start, &nextPos, &len, &kind)
	       return -1
	    endIf
            if kind == ' '
              GetWord (str, &inFile, start, len)
              gotInFile = true
            else
              Print ("sh: Missing name for redirect.\n")
              argc = 0
	      exitVal = 1
              break
            endIf
          elseIf kind == '>' && !gotOutFile
            if !FindNextWord (str, &start, &nextPos, &len, &kind)
	       return -1
	    endIf
            if kind == ' '
              GetWord (str, &outFile, start, len)
              gotOutFile = true
            else
              Print ("sh: Missing name for redirect.\n")
              argc = 0
	      exitVal = 1
              break
            endIf
          else
            Print ("sh: Command line problems\n")
            argc = 0
            break
          endIf
        endWhile

        -- Make sure we got a command...
        if argc == 0
          return 0
        endIf

	-- Make the args array
        *((&argv) asPtrTo int) = argc
	for i = 0 to argc-1
	   argv[i] = & args[i]
	endFor

	-- Open redirected files
        if gotInFile
	    if cinFd != inFd
	       Sys_Close (cinFd)
	    endIf
            cinFd = Sys_Open (&inFile, O_READ,0)
            if cinFd < 0
	      Print (&inFile)
              Print (": No such input file.\n")
	      exitVal = 1
              return -1
            endIf
         endIf
         if gotOutFile
	    if coutFd != outFd
	       Sys_Close (coutFd)
	    endIf
            coutFd = Sys_Open (&outFile,O_WRITE|O_MAYCREATE,6)
            if i < 0
	      Print (&outFile)
              Print (": No such output file.\n")
	      exitVal = 1
	      return -1
            endIf
         endIf

        
        -- Check for built-ins
	exitVal = 0
        if StrEqual (argv[0], "exit")
          Print ("[Shell process terminated]\n")
          Sys_Exit (0)
	elseIf StrEqual (argv[0], "echo")
	  i = 1
	  if argv arraySize > 1 && StrEqual (argv[1], "-n")
	     printNL = false
	     i = 2
          else
             printNL = true
          endIf
	  while i < argv arraySize 
	     dPrint (coutFd, argv[i])
	     if i != argv arraySize -1
               dPrint (coutFd," ")
	     endIf
	     i = i + 1
          endWhile
	  if printNL
	    dPrint (coutFd,"\n")
          endIf
	  closeRedir(inFd, cinFd, outFd, coutFd)
	  return 0
	elseIf StrEqual (argv[0], "cd")
	  if argv arraySize == 1
             if Sys_Chdir ("/") != 0
	        Print ("cd: error\n")
		exitVal = 1
	     endIf
	     closeRedir(inFd, cinFd, outFd, coutFd)
	     return 0
          elseIf argv arraySize == 2
             if Sys_Chdir (argv[1]) != 0
	        Print ("cd: error\n")
		exitVal = 1
	     endIf
	     closeRedir(inFd, cinFd, outFd, coutFd)
	     return 0
	  else
	        Print ("cd: too many arguments.\n")
		closeRedir(inFd, cinFd, outFd, coutFd)
		exitVal = 1
		return -1
	  endIf
	elseIf StrEqual (argv[0], "set")
	  rv = 0
	  if argv arraySize != 3
	      Print ("Usage: set name value\n")
	      exitVal = 1
	      rv = -1
	  elseIf ! setEnv (argv[1], argv[2])
	      Print ("argv[1]") Print (": not set.\n")
	      exitVal = 1
	      rv = -1
          endIf
	  closeRedir(inFd, cinFd, outFd, coutFd)
	  return rv
        elseIf StrEqual (argv[0], "unset")
          rv = 0
	  if argv arraySize != 2
	      Print ("Usage: unset name\n")
	      exitVal = 1
	      rv = -1
	  else
	      unsetEnv(argv[1])
	  endIf
	  closeRedir(inFd, cinFd, outFd, coutFd)
	  return rv
        endIf

        -- Execute the program and wait for it to terminate...
        pid = Sys_Fork ()
        if pid == 0
	  if cinFd != 0
	     Sys_Close(0)
	     i = Sys_Dup(cinFd)
	  endIf
	  if coutFd != 1
	     Sys_Close(1)
	     i = Sys_Dup(coutFd)
	  endIf
          i = Sys_Exec (&args[0],&argv)
	  *((&tempStr) asPtrTo int) = COMMAND_MAX
	  StrCopy (&tempStr, "/bin/")
	  *((&tempStr) asPtrTo int) = 5
	  Append (&tempStr, &args[0], COMMAND_MAX)
	  i = Sys_Exec (&tempStr,&argv)
          Print ("sh: ")
	  Print (argv[0])
	  Print (": Command not found.\n")
          Sys_Exit (127)
        else
	  if wait
	      exitVal = Sys_Join (pid)
	  else
	      rv = pid
	  endIf
        endIf

	closeRedir(inFd, cinFd, outFd, coutFd)

	return rv

    endFunction

-----------------------------  GetWord  ---------------------------------

  function GetWord (cmd: String, str: String, start, len: int)
    --
    -- This function moves "len" characters from "commandLine" (starting
    -- at "start") into the string "str".  It assumes that "str" is large
    -- enough.
    --  Modification:  Does not move " characters.
    var sx, dx: int

      *(str asPtrTo int) = len
      dx = 0
      for sx = start to start + len - 1
          if cmd[sx] != '"'
	      str[dx] = cmd[sx]
	      dx = dx + 1
	  endIf
      endFor
      *(str asPtrTo int) = dx
    endFunction

  function Append (str, toAppend : String, maxLen: int )
    var ix: int
        toCopy: int = toAppend arraySize
	start: int = str arraySize

      if start + toCopy > maxLen
         toCopy = maxLen - start
      endIf

      *(str asPtrTo int) = start + toCopy
      for ix = 0 to toCopy -1
         str[start + ix] = toAppend[ix]
      endFor

    endFunction

--------------------------- StrChr -----------------------------

  function StrChr (str:String, start: int, ch: char) returns int
    var ix: int 
       for ix = start to str arraySize -1
         if str[ix] == ch
	     return ix
	 endIf
       endFor
       return -1
    endFunction
  
endCode
