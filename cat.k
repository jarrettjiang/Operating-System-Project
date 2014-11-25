code cat

  -----------------------------------
  ----                           ----
  ----    BLITZ "cat" Program    ----
  ----                           ----
  -----------------------------------

-----------------------------  main  ---------------------------------

  const BUFF_MAX = 8192

  var buffer: array [BUFF_MAX] of char

  function main ()
    --
    -- This is a simplified version of the 'cat' program found in Unix.
    --
    var ix, infd: int

    if cmdArgs arraySize == 1
        CopyFile(stdin, stdout)
    else
      -- Open a list of files
      for ix = 1 to cmdArgs arraySize -1
         infd = Sys_Open (cmdArgs[ix],O_READ,0)
	 if infd < 0
	    Print ("cat: ")
	    Print (cmdArgs[ix])
	    Print (": file not found\n")
	    Sys_Exit (1)
	 endIf
	 CopyFile (infd, stdout)
	 Sys_Close (infd)
      endFor
    endIf
  endFunction

  function CopyFile (inFd, outFd: int)
    var i: int
      *((& buffer) asPtrTo int) = BUFF_MAX
      while true
        i = Sys_Read (inFd, &buffer[0], BUFF_MAX)
        if i <= 0
          break
        endIf
        i = Sys_Write (outFd, &buffer[0], i)
      endWhile
    endFunction

endCode
