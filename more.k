code more

  -----------------------------------
  ----                           ----
  ----    BLITZ "more" Program    ----
  ----                           ----
  -----------------------------------

-----------------------------  main  ---------------------------------

  const BUFF_MAX = 8192

  var buffer: array [BUFF_MAX] of char
     lineCnt: int
      termFd: int

  function main ()
    --
    -- This is a simplified version of the 'cat' program found in Unix.
    --
    var ix, infd: int
	rv: int
	inChar: char
	

    termFd = Sys_Open("/dev/serial", O_RDWR, 0)
    if termFd < 0
       Print ("more: could not open /dev/serial\n")
       Sys_Exit(1)
    endIf

    if cmdArgs arraySize == 1
        lineCnt = 0
        CopyFile(stdin, stdout)
    else
      -- Open a list of files
      for ix = 1 to cmdArgs arraySize -1
         infd = Sys_Open (cmdArgs[ix],O_READ,0)
	 if infd < 0
	    Print ("more: ")
	    Print (cmdArgs[ix])
	    Print (": file not found\n")
	    Sys_Exit (1)
	 endIf
	 lineCnt = 0
	 CopyFile (infd, stdout)
	 Sys_Close (infd)
	 if ix < cmdArgs arraySize -1
	    dPrint(termFd, "\n")
	    dPrint(termFd, cmdArgs[ix+1])
	    dPrint(termFd, ": ")
	    rv = Sys_Read(termFd, &inChar, 1)
	    while rv == 1 && inChar != '\n'
	      rv = Sys_Read(termFd, &inChar, 1)
	    endWhile
	    dPrint(termFd, "\n")
	 endIf
      endFor
    endIf
  endFunction

  function CopyFile (inFd, outFd: int)
    var i: int
       ix: int
       sx: int
       rv: int
       inChar: char

      *((& buffer) asPtrTo int) = BUFF_MAX
      while true
        i = Sys_Read (inFd, &buffer[0], BUFF_MAX)
        if i <= 0
          break
        endIf
	ix = 0
	sx = 0
	while ix < i
	   while ix < i && lineCnt < 20
	      if buffer[ix] == '\n'
	         lineCnt = lineCnt + 1
	      endIf
              ix = ix + 1
           endWhile
	   if lineCnt == 20
	      rv = Sys_Write (outFd, &buffer[sx], ix-sx)
	      dPrint(termFd, "more: ")
	      rv = Sys_Read(termFd, &inChar, 1)
	      Print ("\b\b\b\b\b\b      \b\b\b\b\b\b")
	      if inChar == '\n'
	         lineCnt = 19
	      elseIf inChar == 'q'
	         return
	      else
	         lineCnt = 0
	      endIf
	      sx = ix
	   endIf
	endWhile
        i = Sys_Write (outFd, &buffer[sx], i-sx)
      endWhile
    endFunction

endCode
