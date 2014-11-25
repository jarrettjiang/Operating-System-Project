code pwd


  function main()
    var
        fd: int
        ent: dirEntry
	stat: statInfo
	rv: int	

	-- The space to assemble the name
	dirname: array [512] of char = new array of char { 512 of '\0' }
	nextCh: int

	-- The inodes of all the directories!
	inodes: array [25] of int = new array of int { 25 of 0 }
	cnt: int

	-- Get the directoires ---
	rv = Sys_Stat (".", &stat)
	if rv < 0
	    Print ("Stat Problems on working directory.\n")
	    Sys_Exit(1)
	endIf

	cnt = 0
	inodes[cnt] = stat.inodeNum
	cnt = cnt+1
	while cnt < 25 && inodes[cnt-1] != 1
	   rv = Sys_Chdir ("..")
	   if rv < 0 
	       Print ("Can't chdir\n")
	       Sys_Exit(1)
	   endIf
	   rv = Sys_Stat (".", &stat)
	   if rv < 0
	       Print ("Stat Problems on working directory.\n")
	       Sys_Exit(1)
	   endIf
	   inodes[cnt] = stat.inodeNum
	   cnt = cnt+1
	endWhile

	if cnt == 25
	   Print ("Directory structure too deep for this simple program.\n")
	   Sys_Exit(1)
	endIf

	-- Construct the directory name
	dirname[0] = '/'
	nextCh = 1

	cnt = cnt - 2
	while cnt >= 0 
	   *((&dirname) asPtrTo int) = nextCh

	   fd = Sys_Opendir (&dirname)
	   if fd < 0
	      Print ("pwd: ") Print (&dirname)
	      Print (": error opening directory.\n")
	      Sys_Exit(1)
	   endIf


	   -- find the entry
	   while Sys_Readdir (fd, &ent) == 0
	      if ent.inodeNum == inodes[cnt]
	          if nextCh != 1
		     Append (&dirname, "/", 255)
		  endIf
		  Append (&dirname, &ent.name, 255)
		  nextCh = dirname arraySize
	          break
	      endIf
           endWhile

	   -- we should have the name in ent
	   if ent.inodeNum != inodes[cnt]
	      Print ("Big problems!  can't find inode...\n")
	      Sys_Exit(1)
	   endIf
	   
	   Sys_Close (fd)
	   cnt = cnt -1

	endWhile

      Print (&dirname) Print("\n")

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


endCode
