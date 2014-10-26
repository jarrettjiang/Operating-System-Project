-----------------------------  DiskDriver  ---------------------------------

  const
    DISK_STATUS_BUSY                               = 0x00000000
    DISK_STATUS_OPERATION_COMPLETED_OK             = 0x00000001
    DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_1   = 0x00000002
    DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_2   = 0x00000003
    DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_3   = 0x00000004
    DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_4   = 0x00000005
    DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_5   = 0x00000006

    DISK_READ_COMMAND  = 0x00000001
    DISK_WRITE_COMMAND = 0x00000002

  behavior DiskDriver
    --
    -- There is only one instance of this class.  It provides "read" and "write"
    -- methods to transfer data from and to the disk.
    --
    -- In this implementation, all I/O is synchronous.  These methods perform
    -- busy-waiting until the disk operation has completed.

      ----------  DiskDriver . Init  ----------

      method Init ()
          print ("Initializing Disk Driver...\n")
          DISK_STATUS_WORD_ADDRESS = 0x00FFFF08 asPtrTo int
          DISK_COMMAND_WORD_ADDRESS = 0x00FFFF08 asPtrTo int
          DISK_MEMORY_ADDRESS_REGISTER = 0x00FFFF0C asPtrTo int
          DISK_SECTOR_NUMBER_REGISTER = 0x00FFFF10 asPtrTo int
          DISK_SECTOR_COUNT_REGISTER = 0x00FFFF14 asPtrTo int
          semToSignalOnCompletion = null
          semUsedInSynchMethods = new Semaphore
          semUsedInSynchMethods.Init (0)
          diskBusy = new Mutex
          diskBusy.Init ()
        endMethod

      ----------  DiskDriver . SynchReadSector  ----------

      method SynchReadSector  (sectorAddr, numberOfSectors, memoryAddr: int)
        --
        -- This method reads "numberOfSectors" sectors (of PAGE_SIZE bytes each)
        -- from the disk and places the data in memory, starting at "memoryAddr".
        -- It waits until the I/O is complete before returning.
        --
        -- If there is a (simulated) disk hardware failure, then this routine
        -- simply tries again in an infinite loop, until it succeeds.
        --
          -- print ("SynchReadSector called\n")
          -- printIntVar ("  sectorAddr", sectorAddr)
          -- printIntVar ("  numberOfSectors", numberOfSectors)
          -- printHexVar ("  memoryAddr", memoryAddr)
          diskBusy.Lock ()
          while true

            self.StartReadSector  (sectorAddr, numberOfSectors, memoryAddr,
                                   & semUsedInSynchMethods)
            semUsedInSynchMethods.Down ()

            -- Check the return status
            switch * DISK_STATUS_WORD_ADDRESS
              case DISK_STATUS_OPERATION_COMPLETED_OK:
                diskBusy.Unlock ()
                return
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_1:
                FatalError ("Disk I/O error in SynchReadSector: Memory addr is not page-aligned or sector count is not positive")
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_2:
                FatalError ("Disk I/O error in SynchReadSector: Attempt to access invalid memory address")
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_3:
                FatalError ("Disk I/O error in SynchReadSector: Bad sectorAddr or sectorCount specifies non-existant sector")
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_4:
                -- This case occurs when there is a hard or soft (simulated)
                -- hardware error while performing the disk operation.
                break
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_5:
                FatalError ("Disk I/O error in SynchReadSector: Bad command word")
              default:
                FatalError ("SynchReadSector: Unexpected status code")
            endSwitch
            -- print ("\n\nIn SynchReadSector: A simulated disk I/O error occurred...\n\n")
          endWhile

        endMethod

      ----------  DiskDriver . StartReadSector  ----------

      method StartReadSector  (sectorAddr, numberOfSectors, memoryAddr: int,
                               whoCares: ptr to Semaphore)
        --
        -- This method reads "numberOfSectors" sectors (of PAGE_SIZE bytes each)
        -- from the disk and places the data in memory, starting at "memoryAddr".
        -- The "whoCares" argument is a Semaphore that we will signal after the
        -- I/O operation is complete; if null no thread will be notified.
        --
          -- print ("StartReadSector called\n")
          -- printIntVar ("  sectorAddr", sectorAddr)
          -- printIntVar ("  numberOfSectors", numberOfSectors)
          -- printHexVar ("  memoryAddr", memoryAddr)
          -- printHexVar ("  whoCares", whoCares asInteger)

          -- Save the semaphore
          semToSignalOnCompletion = whoCares

          -- Move the parameters to the disk and start the I/O
          * DISK_MEMORY_ADDRESS_REGISTER = memoryAddr
          * DISK_SECTOR_NUMBER_REGISTER = sectorAddr
          * DISK_SECTOR_COUNT_REGISTER = numberOfSectors
          * DISK_COMMAND_WORD_ADDRESS = DISK_READ_COMMAND    -- Starts the I/O
        endMethod

      ----------  DiskDriver . SynchWriteSector  ----------

      method SynchWriteSector  (sectorAddr, numberOfSectors, memoryAddr: int)
        --
        -- This method writes "numberOfSectors" sectors (of PAGE_SIZE bytes each)
        -- to the disk.  It waits until the I/O is complete before returning.
        --
        -- If there is a (simulated) disk hardware failure, then this routine
        -- simply tries again in an infinite loop, until it succeeds.
        --
          -- print ("SynchWriteSector called\n")
          -- printIntVar ("  sectorAddr", sectorAddr)
          -- printIntVar ("  numberOfSectors", numberOfSectors)
          -- printHexVar ("  memoryAddr", memoryAddr)
          diskBusy.Lock ()
          while true
            self.StartWriteSector  (sectorAddr, numberOfSectors, memoryAddr,
                                    & semUsedInSynchMethods)
            semUsedInSynchMethods.Down ()

            -- Check the return status
            switch * DISK_STATUS_WORD_ADDRESS
              case DISK_STATUS_OPERATION_COMPLETED_OK:
                diskBusy.Unlock ()
                return
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_1:
                FatalError ("Disk I/O error in SynchWriteSector: Memory addr is not page-aligned or sector count is not positive")
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_2:
                FatalError ("Disk I/O error in SynchWriteSector: Attempt to access invalid memory address")
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_3:
                FatalError ("Disk I/O error in SynchWriteSector: Bad sectorAddr or sectorCount specifies non-existant sector")
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_4:
                -- This case occurs when there is a hard or soft (simulated)
                -- hardware error while performing the disk operation.
                break
              case DISK_STATUS_OPERATION_COMPLETED_WITH_ERROR_5:
                FatalError ("Disk I/O error in SynchWriteSector: Bad command word")
              default:
                FatalError ("SynchWriteSector: Unexpected status code")
            endSwitch
            -- print ("\n\nIn SynchWriteSector: A simulated disk I/O error occurred...\n\n")
          endWhile

        endMethod

      ----------  DiskDriver . StartWriteSector  ----------

      method StartWriteSector  (sectorAddr, numberOfSectors, memoryAddr: int,
                                whoCares: ptr to Semaphore)
        --
        -- This method writes "numberOfSectors" sectors (of PAGE_SIZE bytes each)
        -- to the disk.  It returns immediately after starting the I/O.
        --
        -- The "whoCares" argument is a Semaphore that we will signal after the
        -- I/O operation is complete; if null no thread will be notified.
        --
          -- print ("SynchWriteSector called\n")
          -- printIntVar ("  sectorAddr", sectorAddr)
          -- printIntVar ("  numberOfSectors", numberOfSectors)
          -- printHexVar ("  memoryAddr", memoryAddr)

          -- Save the semaphore
          semToSignalOnCompletion = whoCares

          * DISK_MEMORY_ADDRESS_REGISTER = memoryAddr
          * DISK_SECTOR_NUMBER_REGISTER = sectorAddr
          * DISK_SECTOR_COUNT_REGISTER = numberOfSectors
          * DISK_COMMAND_WORD_ADDRESS = DISK_WRITE_COMMAND    -- Starts the I/O
        endMethod

    endBehavior

-----------------------------  FileManager  ---------------------------------

  behavior FileManager

      ----------  FileManager . Init  ----------

      method Init ()
        --
        -- This method is called once at kernel startup time to initialize
        -- the one and only "FileManager" object.  It is passed a pointer
        -- to a frame of memory. 
        --
        var i: int

          print ("Initializing File Manager...\n")
          fileManagerLock = new Mutex
          fileManagerLock.Init ()

          -- Initialize the FileControlBlock stuff
          fcbFreeList = new List [FileControlBlock]
          anFCBBecameFree = new Condition
          anFCBBecameFree.Init ()
          fcbTable = new array of FileControlBlock
                { MAX_NUMBER_OF_FILE_CONTROL_BLOCKS of new FileControlBlock }
          for i = 0 to MAX_NUMBER_OF_FILE_CONTROL_BLOCKS-1
            fcbTable[i].Init()
	    fcbTable[i].inode.Init()
            fcbFreeList.AddToEnd (&fcbTable[i])
          endFor

          -- Initialize the OpenFile stuff
          openFileFreeList = new List [OpenFile]
          anOpenFileBecameFree = new Condition
          anOpenFileBecameFree.Init ()
          openFileTable = new array of OpenFile
                { MAX_NUMBER_OF_OPEN_FILES of new OpenFile }
          for i = 0 to MAX_NUMBER_OF_OPEN_FILES-1
            openFileFreeList.AddToEnd (&openFileTable[i])
          endFor

          -- Create the special "stdin/stdout" open file
          serialTerminalFile = new OpenFile
          serialTerminalFile.kind = TERMINAL

         endMethod

      ----------  FileManager . Print  ----------

      method Print ()
        var i: int
          fileManagerLock.Lock ()           -- Need lock since we touch freeLists
          print ("Here is the FileControlBlock table...\n")
          for i = 0 to MAX_NUMBER_OF_FILE_CONTROL_BLOCKS-1
            print ("  ")
            printInt (i)
            print (":  ")
            fcbTable[i].Print()
          endFor
          print ("Here is the FREE list of FileControlBlocks:\n   ")
          fcbFreeList.ApplyToEach (printFCB)
          nl ()
          print ("Here is the OpenFile table...\n")
          for i = 0 to MAX_NUMBER_OF_OPEN_FILES-1
            print ("  ")
            printInt (i)
            print (":  0x")
            printHex ((& openFileTable[i]) asInteger)
            print (":  ")
            openFileTable[i].Print()
          endFor
          print ("Here is the FREE list of OpenFiles:\n")
          openFileFreeList.ApplyToEach (printOpen)
          fileManagerLock.Unlock ()
        endMethod

      ----------  FileManager . Open  ----------

      method Open (filename: String, dir: ptr to OpenFile, flags, mode: int)
      	     returns ptr to OpenFile
      --
      -- This method is called to open a file.  It returns pointer to
      -- a newly allocated OpenFile.  It will set its "numberOfUsers"
      -- count to 1.
      --
      -- The file must already exist on the disk.  If it cannot be found,
      -- this method returns null.
      --
      -- This method is reentrant, and may block the caller.
      --
          var open: ptr to OpenFile
              fcb: ptr to FileControlBlock
	      iNum: int
	      isRoot: bool

	  isRoot = StrCmp(filename, "/") == 0 

	  -- Quick check for sanity
	  if fileSystem.rootDirectory == null && !isRoot
	    return null
	  endIf

	  -- Get the inode number
	  iNum = fileSystem.NameToInodeNum (filename, dir)
	  if iNum < 0
	     return null
	  endIf

          -- First, get an FCB that points to the file.
          -- This will increment fcb.numberOfUsers.
          fcb = fileManager.GetFCB (iNum)
          if fcb == null
            return null
          endIf

	  -- Process open() flags && permission checking
	  -- UNIMPLEMENTED

          -- Next, allocate an OpenFile, waiting if necessary.
          open = self.GetAnOpenFile(true)

          -- Connect it to this FCB and set its "numberOfUsers" count.
          fileManagerLock.Lock()
	  if (fcb.inode.mode & TYPE_FILE) == TYPE_FILE
             open.Init (FILE, fcb)
	  else
	     open.Init (DIRECTORY, fcb)
	  endIf

          -- Release FileManagerLock and return a pointer to the OpenFile object
          fileManagerLock.Unlock()

          -- printHexVar ("open.fcb", open.fcb asInteger)

          return open
        endMethod

      ----------  FileMangger . GetAnOpenFile --------
      method GetAnOpenFile (block: bool) returns ptr to OpenFile
        var open: ptr to OpenFile
          fileManagerLock.Lock()
          if openFileFreeList.IsEmpty() && !block
	     fileManagerLock.Unlock()
	     return null
	  endIf
          while openFileFreeList.IsEmpty ()
            anOpenFileBecameFree.Wait (& fileManagerLock)
          endWhile
          open = openFileFreeList.Remove ()
	  fileManagerLock.Unlock ()
	  return open

        endMethod

      ----------  FileMangger . LookupFCB --------
      method LookupFCB (inodeNum: int) returns
      	      ptr to FileControlBlock

        var i: int
         for i = 0 to MAX_NUMBER_OF_FILE_CONTROL_BLOCKS-1
            if fcbTable[i].inode.number == inodeNum
              return &fcbTable[i]
            endIf
          endFor
	  return null
        endMethod

      ----------  FileManager . GetFCB  ----------

      method GetFCB (inodeNum: int ) returns ptr to FileControlBlock
      --
      -- This method is called when opening a file.  It will search
      -- the fcbTable for an entry matching the file, that is the inode number.
      -- If none is found, a new FCB is returned
      --
      -- The file must already exist on the disk.  If it cannot be found,
      -- this method returns null. 
      --
      -- The numberOfUsers field in the FCB is set to one.
      --
      -- This method is reentrant, and may block the caller.
      --
          var
              fcb: ptr to FileControlBlock

          --printIntVar ("GetFCB: inodeNum", inodeNum)

          fileManagerLock.Lock()

          -- See if there is an FCB for this file; if so return it.
	  fcb = self.LookupFCB (inodeNum)
	  if fcb != null
             fcb.numberOfUsers = fcb.numberOfUsers + 1
             fileManagerLock.Unlock()
             return fcb
          endIf

          -- Get an unused FCB, waiting until one becomes available
          while fcbFreeList.IsEmpty ()
            anFCBBecameFree.Wait (& fileManagerLock)
          endWhile
          fcb = fcbFreeList.Remove ()

          fcb.numberOfUsers = 1

          -- Safe to unlock now, inode read will provide its own synch 
          fileManagerLock.Unlock()

          -- Check for correctness of new fcb returned 
          if fcb.relativeSectorInBuffer >= 0 || fcb.bufferIsDirty
            FatalError (
	       "In FileManager.Open: a free FCB appears not to have been closed properly")
          endIf

          -- Read the inode ...
	  fcb.inode.GetInode (inodeNum)

	  -- Now return the fcb
          return fcb
        endMethod

      ----------  FileManager . Close  ----------
      --
      -- This method is called to close an OpenFile.  If there is a pending
      -- write (i.e., the buffer is dirty) then it is written out first.
      --
      -- The "numberOfUsers" for the OpenFile is decremented and, if zero,
      -- the OpenFile is freed.  If the OpenFile is freed, then the
      -- "numberOfUsers" for the FCB is decremented.  If it too is zero, the
      -- FCB is freed.
      --
      method Close (open: ptr to OpenFile)
          var fcb: ptr to FileControlBlock
          if open == & serialTerminalFile
            return
          endIf
          fileManagerLock.Lock()
          open.fcb.Flush()
          fcb = open.fcb
          open.numberOfUsers = open.numberOfUsers - 1
          if open.numberOfUsers <= 0
            openFileFreeList.AddToEnd (open)
            anOpenFileBecameFree.Signal (& fileManagerLock)
            fcb.Release(&fileManagerLock)
          endIf
          fileManagerLock.Unlock()
        endMethod

       ----------  FileManager . SynchRead  ----------

      method SynchRead (open: ptr to OpenFile, 
                        targetAddr, bytePos, numBytes: int) returns bool
          --
          -- This method reads "numBytes" from this file and stores
          -- them at the address pointed to by "targetAddr".  If everything
          -- was read okay, it returns TRUE; if problems it returns FALSE.
          --
          -- It reads a page at a time into an internal buffer
          -- by calling "diskDriver.SynchReadSector".
          --
          var sector, offset, posInBuffer, bytesToMove: int
	   -- dataSector: int
              fcb: ptr to FileControlBlock
          --printHexVar ("SynchRead called  targetAddr", targetAddr)
          --printIntVar ("                  bytePos", bytePos)
          --printIntVar ("                  numBytes", numBytes)
          fileManagerLock.Lock()
          if ! open || ! open.fcb || open.fcb.inode.number < 0
            FatalError ("FileManager.SynchRead: file not properly opened")
          endIf
          fcb = open.fcb
          while numBytes > 0
            -- At this point targetAddr and numBytes tell what work is left to do.
            -- printHexVar ("NEXT MOVE:\n  targetAddr", targetAddr)
            -- printIntVar ("  numBytes", numBytes)
            -- printHexVar ("          ", numBytes)
            -- printIntVar ("  relativeSectorInBuffer", fcb.relativeSectorInBuffer)
            -- printIntVar ("  bytePos", bytePos)
            -- printHexVar ("         ", bytePos)
            sector = bytePos / PAGE_SIZE
            offset = bytePos % PAGE_SIZE
            -- printIntVar ("  sector", sector)
            -- printIntVar ("  offset", offset)
            -- printHexVar ("        ", offset)
            if fcb.relativeSectorInBuffer != sector
	        if !open.fcb.ReadSector(sector) 
		   return false
		endIf
            endIf
            posInBuffer = fcb.bufferPtr + offset
            bytesToMove = Min (numBytes, PAGE_SIZE - offset)
            -- printHexVar ("  MOVING - targetAddr", targetAddr)
            -- printHexVar ("         - source addr (posInBuffer)", posInBuffer)
            -- printIntVar ("         - bytesToMove", bytesToMove)
            MemoryCopy (targetAddr, posInBuffer, bytesToMove)
            targetAddr = targetAddr + bytesToMove
            bytePos = bytePos + bytesToMove
            numBytes = numBytes - bytesToMove
            -- printHexVar ("  NEW targetAddr", targetAddr)
            -- printIntVar ("  NEW bytePos", bytePos)
            -- printHexVar ("             ", bytePos)
            -- printIntVar ("  NEW numBytes", numBytes)
            -- printHexVar ("              ", numBytes)
          endWhile
          fileManagerLock.Unlock()
          return true
        endMethod

      ----------  FileManager . SynchWrite  ----------

      method SynchWrite (open: ptr to OpenFile, 
                         sourceAddr, bytePos, numBytes: int) returns bool
          --
          -- This method reads "numBytes" from the memory address "sourceAddr"
          -- and writes them to the file at "bytePos".  If everything
          -- was written okay, it returns TRUE; if problems it returns FALSE.
          --
          -- It operates on an internal buffer by calling
          -- "diskDriver.SynchReadSector" and "diskDriver.SynchWriteSector".
          --
          var sector, offset, posInBuffer, bytesToMove: int
              fcb: ptr to FileControlBlock

          -- print ("--------------------\n")
          -- printHexVar ("SynchWrite called  sourceAddr", sourceAddr)
          -- printIntVar ("                   bytePos", bytePos)
          -- printIntVar ("                   numBytes", numBytes)
	  -- open.fcb.inode.Print()
          fileManagerLock.Lock()
          if ! open || ! open.fcb || open.fcb.inode.number < 0
              FatalError ("FileManager.SynchWrite: file not properly opened")
          endIf
          fcb = open.fcb
          while numBytes > 0
            -- At this point sourceAddr and numBytes tell what work is left to do.
            -- printHexVar ("NEXT MOVE:\n  sourceAddr", sourceAddr)
            -- printIntVar ("  numBytes", numBytes)
            -- printHexVar ("          ", numBytes)
            -- printIntVar ("  relativeSectorInBuffer", fcb.relativeSectorInBuffer)
            -- printIntVar ("  bytePos", bytePos)
            -- printHexVar ("         ", bytePos)
            sector = bytePos / PAGE_SIZE
            offset = bytePos % PAGE_SIZE
            -- printIntVar ("  sector", sector)
            -- printIntVar ("  offset", offset)
            bytesToMove = Min (numBytes, PAGE_SIZE - offset)
            if offset == 0 && bytesToMove == PAGE_SIZE
              -- No need to read the sector first
              open.fcb.Flush()
            elseIf fcb.relativeSectorInBuffer != sector
	      -- Read the sector before we do a partial write
	      if !fcb.ReadSector (sector)
	         return false
	      endIf
            endIf
            posInBuffer = fcb.bufferPtr + offset
            fcb.relativeSectorInBuffer = sector
            fcb.bufferIsDirty = true
            -- printHexVar ("  MOVING - sourceAddr", sourceAddr)
            -- printHexVar ("         - target (posInBuffer)", posInBuffer)
            -- printIntVar ("         - bytesToMove", bytesToMove)
            MemoryCopy (posInBuffer, sourceAddr, bytesToMove)
            sourceAddr = sourceAddr + bytesToMove
            bytePos = bytePos + bytesToMove
            numBytes = numBytes - bytesToMove
            -- printHexVar ("  NEW sourceAddr", sourceAddr)
            -- printIntVar ("  NEW bytePos", bytePos)
            -- printHexVar ("             ", bytePos)
            -- printIntVar ("  NEW numBytes", numBytes)
            -- printHexVar ("              ", numBytes)
          endWhile
          fileManagerLock.Unlock()
          -- print ("--------------------\n")
          return true
        endMethod

    endBehavior

  function copyUnalignedWord (destPtr, fromPtr: ptr to int)
      var from, dest: ptr to char
      from = fromPtr asPtrTo char
      dest = destPtr asPtrTo char
      *dest = *from
      *(dest+1) = *(from+1)
      *(dest+2) = *(from+2)
      *(dest+3) = *(from+3)
    endFunction

  function printFCB (fcb: ptr to FileControlBlock)
      printInt (fcb.inode.number)
      printChar (' ')
    endFunction

  function printOpen (open: ptr to OpenFile)
      print ("  0x")
      printHex (open asInteger)
      print (":  ")
      open.Print ()
    endFunction

-----------------------------  ToyFs         --------------------------------

  behavior ToyFs

      --------------- ToyFs . Init  ----------------

      method Init()
        var
            p: ptr to int

	  -- Get a frame for inode manipulations and initialize the lock
	  inodeBuffer = frameManager.GetAFrame ()
	  inodeBuffSec = -1
 	  fsLock = new Mutex
	  fsLock.Init ()

          -- Read in sector 0 from the disk.  This is the super bloc,
 	  superBlock = frameManager.GetAFrame ()
          diskDriver.SynchReadSector (0,    -- sector to read
                                      1,    -- number of sectors to read
                                      superBlock)
	  p = superBlock asPtrTo int

          if *p != 0x54794673 -- "TyFs", the ToyFs magic number
            FatalError ("Magic number in sector 0 of ToyFs file system is bad")
          endIf

	  -- Get file system parameters
	  p = p+4
	  fssize = *p
	  p = p+4
          numInodes = *p

	  --print ("super: fssize: ")  printInt (fssize)
          --print (" inodes: ") printInt (numInodes)
          --print ("\n")

	  -- Skip over unused integer
	  p = p+8
	  i_bitmap = new BitMap
	  i_bitmap.InitFromPtr(numInodes, p asPtrTo array of int)
	  --print ("inode ") i_bitmap.Print()

	  -- Move over i_bitmap
          p = p + *p*4 + 4
	  d_bitmap = new BitMap
	  d_bitmap.InitFromPtr(*p*32-1, p asPtrTo array of int)
	  --print ("data ") d_bitmap.Print()

	  -- offset for data sectors
	  fileSystem.dataSecOffset =  numInodes / INODES_PER_SEC
	  --printIntVar ("dataSecOffset: ", fileSystem.dataSecOffset)

	  -- Create the Root Directory
	  rootDirectory = null
	  rootDirectory = fileManager.Open("/",null,O_READ,0)
	  rootDirectory.kind = DIRECTORY

       endMethod

      --------------- ToyFs . SaveSuper  ----------------
    method SaveSuper ()
          diskDriver.SynchWriteSector (0,    -- sector to Write
                                       1,    -- number of sectors to read
                                       superBlock)
      endMethod


      --------------- ToyFs . OpenLastDir  ----------------

    method OpenLastDir (filename: String, startDir: ptr to OpenFile,
    	   	        lastElIndex: ptr to int) returns ptr to OpenFile
        var
	    elName: array [ MAX_STRING_SIZE ] of char
	    ix : int
	    sIx: int
	    eIx: int
	    sizeP: ptr to int
	    entPtr: ptr to dirEntry
	    elDir: ptr to OpenFile
	    iNode: InodeData
	    fcb: ptr to FileControlBlock

	    elName = new array [ MAX_STRING_SIZE ] of char 
	    	     	 { MAX_STRING_SIZE of '\0' }
	    sizeP = (&elName) asPtrTo int
	    iNode = new InodeData
	    *lastElIndex = -1

	    ix = StrChr (filename, '/', 0)
	    if ix < 0
	       *lastElIndex = 0
	       return startDir.NewReference()
	    endIf

	    if ix == 0
	       elDir = fileSystem.rootDirectory.NewReference()
	       sIx = 1
	       eIx = StrChr(filename, '/', 1)
	    else
	       elDir = startDir.NewReference()
	       eIx = ix
	       sIx = 0
	    endIf

	    -- Loop through
	    while eIx > 0
	      -- Copy File name
	      if eIx - sIx > MAX_STRING_SIZE
	         fileManager.Close(elDir)
		 return null
	      endIf
	      for ix = 0 to eIx-sIx-1
	         elName[ix] = filename[sIx+ix]
	      endFor
	      *sizeP = eIx-sIx

	      -- Get the entry
	      -- print("OpenLastDir: elName: ") print(&elName) nl()
	      entPtr = elDir.Lookup(&elName)
	      if entPtr == null
	          fileManager.Close(elDir)
		  return null
	      endIf
	      iNode.GetInode(entPtr.inodeNum)
	      if (iNode.mode & TYPE_DIR) != TYPE_DIR
	          fileManager.Close(elDir)
		  return null
	      endIf

	      -- Get FCB / OpenFile ...
	      fcb = fileManager.GetFCB(entPtr.inodeNum)
	      fileManager.Close(elDir)
	      if fcb == null
		 return null
	      endIf

	      -- Get an OpenFile
	      elDir = fileManager.GetAnOpenFile(false)
	      if elDir == null
		 return null
	      endIf
	      elDir.Init(DIRECTORY,fcb)

	      -- Update for next element
	      sIx = eIx+1
	      eIx = StrChr (filename, '/', sIx)
	    endWhile
	    
	    *lastElIndex = sIx
	    return elDir

      endMethod


      --------------- ToyFs . NameToInodeNum  ----------------

    method NameToInodeNum (filename: String, dir : ptr to OpenFile) returns int
        var 
	    dirEnt: ptr to dirEntry
	    curDir: ptr to OpenFile  -- for walking the tree
	    retVal: int
	    lastElStart: int
	    lastElName: array [ MAX_STRING_SIZE ] of char
	    ix: int

	--print ("NameToInodeNum: looking for ") print (filename) print (" (len is ")
        --printInt (filename arraySize) print (")\n")

	-- Quick check for root dir
        if StrCmp (filename, "/") == 0
	   return 1
        endIf

	-- initialize the search
	if dir.kind != DIRECTORY 
	   FatalError ("NameToInodeNum on non-Directory file.")
	endIf

	-- Start at
	curDir = self.OpenLastDir (filename, dir, &lastElStart)
	if (curDir == null)
	    return -1
        endIf
	
	-- Do the lookup(s) ....
	*((&lastElName) asPtrTo int) = filename arraySize - lastElStart
	for ix = 0 to filename arraySize - lastElStart -1
	   lastElName[ix] = filename[lastElStart+ix]
	endFor
	--print ("NameToInodeNum: last element is: ") print (&lastElName) nl()
	dirEnt = curDir.Lookup(&lastElName)

	if dirEnt == null
	   fileManager.Close(curDir)
	   return -1
	endIf
	retVal = dirEnt.inodeNum
	fileManager.Close(curDir)

	return retVal
      endMethod

      --------------- ToyFs . AllocInode  ----------------
    method AllocInode () returns int
      var retVal: int
          idata: InodeData
        fsLock.Lock()
        retVal = i_bitmap.FindZeroAndSet()
	self.SaveSuper()
	fsLock.Unlock()
	idata = new InodeData
	idata.number = retVal
	idata.nlinks = 0
	idata.mode = 0
	idata.fsize = 0
	idata.balloc = 0
	idata.direct = new array [10] of int { 10 of 0 }
	idata.indir1 = 0
	idata.indir2 = 0
	idata.dirty = true
	idata.indSec = -1
	idata.WriteInode()
	return retVal
      endMethod

      --------------- ToyFs . FreeInode  ----------------
    method FreeInode (iNum: int)
        fsLock.Lock()
        i_bitmap.ClearBit(iNum)
	self.SaveSuper()
	fsLock.Unlock()
      endMethod

        --------------- ToyFs . AllocDataBlock  ----------------
    method AllocDataBlock () returns int
      var retVal: int
        fsLock.Lock()
        retVal = d_bitmap.FindZeroAndSet()
	self.SaveSuper()
	fsLock.Unlock()
	return retVal
      endMethod

      --------------- ToyFs . FreeDataBlock  ----------------
    method FreeDataBlock (dbNum: int)
        fsLock.Lock()
         d_bitmap.ClearBit(dbNum)
	self.SaveSuper()
	fsLock.Unlock()
      endMethod

      --------------- ToyFs . ReadFile  ----------------
    method ReadFile (file: ptr to OpenFile, userBuffer: ptr to char,
                     sizeInBytes: int)  returns int
         FatalError ("ToyFs . ReadFile Not Implemented.")
         return -1
      endMethod

      --------------- ToyFs . WriteFile  ----------------

    method  WriteFile (file: ptr to OpenFile, userBuffer: ptr to char,
                       sizeInBytes: int)  returns int
         FatalError ("ToyFs . WriteFile Not Implemented.")
         return -1
      endMethod

      --------------- ToyFs . CreateFile  ----------------

    method CreateFile (filename: String, mode: int) returns int
         FatalError ("ToyFs . CreateFile Not Implemented.")
         return -1
      endMethod

      --------------- ToyFs . MakeDir  ----------------

    method MakeDir (dirname: String) returns int
         FatalError ("ToyFs . MakeDir Not Implemented.")
         return -1
      endMethod

      --------------- ToyFs . RemoveDir  ----------------

    method RemoveDir (dirname: String) returns int
        FatalError ("ToyFs . MakeDir Not Implemented.")
         return -1
      endMethod

      --------------- ToyFs . Link  ----------------

    method Link (oldname, newname: String) returns int
         FatalError ("ToyFs . MakeDir Not Implemented.")
         return -1
     endMethod


      --------------- ToyFs .Unlink   ----------------

    method Unlink (filename: String) returns int
        FatalError ("ToyFs . MakeDir Not Implemented.")
         return -1
      endMethod


  endBehavior


-----------------------------  InodeData         --------------------------------

  behavior InodeData

      ---------- InodeData . Init  -----------
      -- This method is called for each file opened,  each FCB has one
      -- This reads the inode data for the file at init time
      -- theLock should be a pointer to the FileManager.fileManagerLock
      -- bufptr should be a pointer to a frame allocated by the FileMangager
      --        for inode reads/writes  (should be improved!)
      -- num is the inode number
      --
      method Init ()
          -- Nothing is valid, set invalid inode number
          number = -1
        endMethod

      --------------- InodeDate . GetInode ----------------
      --
      -- Gets an inode from the disk
      -- 

      method GetInode ( num : int )
          var inodeSec : int
	      p : ptr to diskInode
              ix : int

	  -- Calculate where to get the inode
	  inodeSec = (num-1) / INODES_PER_SEC
	  fileSystem.fsLock.Lock()

	  -- Read the proper one
	  if (fileSystem.inodeBuffSec != inodeSec)
	     -- Read the proper sector 
            diskDriver.SynchReadSector ( inodeSec + 1,  1,
                       fileSystem.inodeBuffer)
            fileSystem.inodeBuffSec = inodeSec
          endIf

	  -- Point to the diskInode
	  p = (fileSystem.inodeBuffer 
	             + (((num - 1) % INODES_PER_SEC) * INODE_SIZE)) asPtrTo diskInode

          --print ("added = ") printInt (((num - 1) % INODES_PER_SEC) * INODE_SIZE) nl()
          --printIntVar ("num", num)
          --print ("p is 0x") printHex ( p asInteger ) nl()

	  -- Set the fields of this in memory Inode
          number = num
	  nlinks = p.nlinksAndMode >> 16
	  mode   = p.nlinksAndMode & 0xff
	  fsize  = p.fsize
	  balloc = p.balloc
	  direct = new array [10] of int { 10 of 0 }
	  for ix = 0 to 9 
	     direct[ix] = p.direct[ix]
	  endFor
	  indir1 = p.indir1
	  indir2 = p.indir2

	  dirty = false
	  indSec = -1      -- -1 means not in use

	  fileSystem.fsLock.Unlock()

	  --print ("GetInode: ")
	  --self.Print()
        endMethod

      method WriteInode()
          var inodeSec : int
	      p : ptr to diskInode
              ix : int

	  if ! dirty
	     return
	  endIf

	  -- Calculate the location of the inode
	  inodeSec = (number-1) / INODES_PER_SEC
	  fileSystem.fsLock.Lock()

	  -- Read the proper one
	  if (fileSystem.inodeBuffSec != inodeSec)
	     -- Read the proper sector 
            diskDriver.SynchReadSector ( inodeSec + 1,  1,
                       fileSystem.inodeBuffer)
            fileSystem.inodeBuffSec = inodeSec
          endIf

	  -- Point to the diskInode
	  p = (fileSystem.inodeBuffer 
	             + (((number - 1) % INODES_PER_SEC) * INODE_SIZE)) asPtrTo diskInode
          *((&p.direct) asPtrTo int) = 10
          p.nlinksAndMode = nlinks << 16 | mode
	  p.fsize = fsize
	  p.balloc = balloc
	  for ix = 0 to 9
	     p.direct[ix] = direct[ix]
	  endFor
	  p.indir1 = indir1
	  p.indir2 = indir2

	  diskDriver.SynchWriteSector ( inodeSec + 1,  1,
                       fileSystem.inodeBuffer)

	  dirty = false
	  fileSystem.fsLock.Unlock()

        endMethod

      method Print()
          var ix : int 
          print ("IN: ")
	  printInt (number) print (" ")
	  if ((mode & TYPE_DIR) == TYPE_DIR)
	    print ("d")
	  else
	    print ("-")
	  endIf
	  if ((mode & MODE_READ) == MODE_READ)
	    print ("r")
	  else
	    print ("-")
	  endIf
	  if ((mode & MODE_WRITE) == MODE_WRITE)
	    print ("w")
	  else
	    print ("-")
	  endIf
	  if ((mode & MODE_EXE) == MODE_EXE)
	    print ("x ")
	  else
	    print ("- ")
	  endIf
	  printInt (nlinks) print (" ")
          printInt (fsize) print (" (")
          printInt (balloc) print (") [")
          for ix = 0 to 9 
             printInt (direct[ix]) 
	     if ix < 9 
	       print (",")
	     else
	       print ("] ")
             endIf
	  endFor
	  printInt (indir1)
	  if (dirty)
             print (" dirty")
	  endIf
          nl()
	  if (indSec != -1 )
	    for ix = 0 to 2047
              if *((indSec + 4*ix) asPtrTo int) != 0 
	         printInt(ix) print("[")
                 printInt (*((indSec + 4*ix) asPtrTo int))  print ("] ")
              endIf
            endFor
            nl()
          endIf
        endMethod

      ----------- InodeData . GetDataSectorNumber () -------------

      -- This is expected to be called with fileManagerLock locked!

      method GetDataSectorNumber ( logicalSector: int ) returns int
        var dbPtr: ptr to int
	  --printIntVar ("GetDataSectorNumber:logicalSector", logicalSector)
       	  if logicalSector < 10 
	      return direct[logicalSector]
          else
              if logicalSector < 2058
	         if indir1 == 0
		    return 0
		 endIf 
	         if indSec <= 0
		    -- Need to load the dbSec
		    self.GetIndirect()
		 endIf
		 dbPtr = (indSec + (logicalSector-10)*4) asPtrTo int
		 return *dbPtr
	      else
	         -- Not implemented
		 FatalError ("Double Indirect not implemented.")
	      endIf
          endIf
     	  return 0
        endMethod

      ----------- InodeData . AllocateNewSector () -------------

      method AllocateNewSector (logicalSector: int) returns bool
        -- Implementation not supplied ....
        return false
      endMethod

      ----------- InodeData . GetIndirect () -------------

      method GetIndirect ()
	
	-- read the indirect block
	indSec = frameManager.GetAFrame() 
	diskDriver.SynchReadSector (indir1 + fileSystem.dataSecOffset, 1, indSec)

	endMethod
  
     ----------- InodeData . SaveIndirect () -------------

      method SaveIndirect ()
	
	   -- read the indirect block
	   if indir1 == 0 || indSec < 0
	      FatalError ("SaveIndirect with no indirect!")
	   endIf
	   diskDriver.SynchWriteSector (indir1 + fileSystem.dataSecOffset, 1, indSec)

	endMethod

      ----------- InodeData . FreeIndirect () -------------

      method FreeIndirect ()

          -- Did we read one?
	  if indSec <= 0
	    return
	  endIf
 	
	  -- Free the frame
	  frameManager.PutAFrame(indSec)
          indSec = -1
        endMethod

      ----------- InodeData . SetMode () -------------

      method SetMode ( newMode: int )
         -- implementation not given
         endMethod

    endBehavior

-----------------------------  FileControlBlock  ---------------------------------

  behavior FileControlBlock

      ----------  FileControlBlock . Init  ----------
      --
      -- This method is called once at startup time.  It preallocates a buffer
      -- in memory which may be needed when I/O is done on the file.
      --
      method Init ()
          numberOfUsers = 0
          bufferPtr = frameManager.GetAFrame ()
          relativeSectorInBuffer = -1
          bufferIsDirty = false
	  inode = new InodeData
         endMethod

      ----------  FileControlBlock . Print  ----------

      method Print ()
          print ("inode.number=")
          printInt (inode.number)
          print (",  numberOfUsers=")
          printInt (numberOfUsers)
          print (",  bufferPtr=")
          printHex (bufferPtr)
          print (",  relativeSectorInBuffer=")
          printInt (relativeSectorInBuffer)
          nl ()
	  print ("Inode: ")
	  inode.Print()
        endMethod

      ----------  FileControlBlock . ReadSector  ----------

      method ReadSector (newSector: int) returns bool
 	var dataSector: int       
	  if (newSector == relativeSectorInBuffer)
	     return true
	  endIf
          if bufferIsDirty
	     self.Flush()
	  endIf
	  -- get the new one
	  relativeSectorInBuffer = newSector
	  dataSector = inode.GetDataSectorNumber(relativeSectorInBuffer)
	  if dataSector == 0
	     MemoryZero (bufferPtr, PAGE_SIZE)
	     return  inode.AllocateNewSector(newSector)
	  else 
             diskDriver.SynchReadSector (
                        dataSector + fileSystem.dataSecOffset, 1, bufferPtr)
	  endIf
	  return true
        endMethod

     ----------  FileControlBlock . Flush  ----------

      method Flush ()
        --
        -- This method writes out the buffer, if it is dirty.  This method
        -- assumes the caller already holds the fileManagerLock.
        -- 
	var dataSector: int

          if bufferIsDirty
            if relativeSectorInBuffer < 0
              FatalError ("FileManager.Flush: buffer is dirty but relativeSectorInBuffer =  -1")
            endIf
            bufferIsDirty = false
	    dataSector = inode.GetDataSectorNumber(relativeSectorInBuffer)
	    if dataSector == 0
	       FatalError ("FCB.Flush ... no disk segment to flush to...")
	    endIf
            diskDriver.SynchWriteSector (
                       dataSector + fileSystem.dataSecOffset, 1, bufferPtr)
          endIf
        endMethod

    ----------  FileControlBlock . Release  ----------

      -- Must be called with fileManagerLock locked.

      method Release (lock: ptr to Mutex)
         numberOfUsers = numberOfUsers - 1
         if numberOfUsers <= 0
	    -- Final close, mark unused and release any indirect frame
	    relativeSectorInBuffer = -1
	    inode.FreeIndirect ()
	    inode.number = -1
            fileManager.fcbFreeList.AddToEnd (self)
            fileManager.anFCBBecameFree.Signal ( lock )
         endIf
        endMethod

    endBehavior


-----------------------------  OpenFile  ---------------------------------

  behavior OpenFile

      ----------  OpenFile . Init  ----------

     method Init (fKind: int, fFcb: ptr to FileControlBlock)
     	  kind = fKind
	  fcb  = fFcb
          currentPos = 0
	  numberOfUsers = 1
	  addPos = -1
       endMethod


      ----------  OpenFile . Print  ----------

      method Print ()
          print ("    OPEN FILE:   currentPos=")
          printInt (currentPos)
	  print (" numOfUsers=") printInt(numberOfUsers)
          print (", fcb=")
          if fcb
            fcb.Print ()
          else
            print ("null\n")
          endIf
        endMethod

      ----------  OpenFile . NewReference  ----------

      method NewReference () returns ptr to OpenFile
           numberOfUsers = numberOfUsers + 1
	   return self
        endMethod

      ----------  OpenFile . ReadBytes  ----------

      method ReadBytes (targetAddr, numBytes: int) returns bool
          --
          -- This method reads "numBytes" from this file and stores
          -- them at the address pointed to by "targetAddr".  If everything
          -- was read okay, it returns TRUE; if problems it returns FALSE.
          --
          -- This method may block the caller.  This method is reentrant.
          --
          var pos: int
          -- printIntVar ("OpenFile.ReadBytes    currentPos", currentPos)
          fileManager.fileManagerLock.Lock ()
          pos = currentPos
          currentPos = currentPos + numBytes
          fileManager.fileManagerLock.Unlock ()
          return fileManager.SynchRead (self, targetAddr, pos, numBytes)
        endMethod

      ----------  OpenFile . ReadInt  ----------

      method ReadInt () returns int
          --
          -- Read the next 4 bytes from a file and return it as an integer.
          --
          var i: int
          if ! self.ReadBytes ((&i) asInteger, 4)
            FatalError ("Within ReadInt: ReadBytes failed")
          endIf
          return i
        endMethod

      ----------  OpenFile . LoadExecutable  ----------

      method LoadExecutable (addrSpace: ptr to AddrSpace) returns int
        --
        -- This method reads an executable "a.out" file from the disk, creates
        -- a virtual address space (with all pages resident in memory), and
        -- loads the executable program into the new address space.
        --
        -- The virtual address space will consist of (in this order):
        --     The environment page(s)     see NUMBER_OF_ENVIRONMENT_PAGES
        --     The text page(s)
        --     The data page(s)
        --     The bss page(s)
        --     The stack page(s)           see USER_STACK_SIZE_IN_PAGES
        --
        -- The given "addrSpace" is assumed to be empty; this method will
        -- allocate new frames and initialize the page table.
        --
        -- If all is okay, this method returns the initial PC, which will be
        -- the address of the first word of the first text page.
        --
        -- If any problems arise, this method returns -1.
        --
          var nextVirtPage, addr: int
              textSize, dataSize, bssSize, textStart, dataStart, bssStart: int
              i, textSizeInPages, dataSizeInPages, bssSizeInPages: int
 
          -- Make sure this address space is empty...
          if addrSpace.numberOfPages != 0
            FatalError ("LoadExecutable: This virtual address space is not empty")
          endIf
         
          -- Read and check the magic number...
          if  self.ReadInt () != 0x424C5A78    -- in ASCII: "BLZx"
            print ("LoadExecutable: Bad magic number\n")
            return -1
          endIf

          -- Read in the header info...
          textSize = self.ReadInt ()
          dataSize = self.ReadInt ()
          bssSize = self.ReadInt ()
          textStart = self.ReadInt ()
          dataStart = self.ReadInt ()
          bssStart = self.ReadInt ()

          -- Compute the size of the text segment in pages...
          if textSize % PAGE_SIZE != 0
            print ("LoadExecutable: The text segment size not a multiple of page size\n")
            return -1
          endIf
          textSizeInPages = textSize / PAGE_SIZE

          -- Environment pages are filled in by the OS; make sure the executable
          -- and the OS agree about how many there are to be...
          if textStart != NUMBER_OF_ENVIRONMENT_PAGES * PAGE_SIZE
            print ("LoadExecutable: The environment size does not")
	    print (" match the 'loadAddr' info supplied to the linker\n")
            return -1
          endIf

          -- Compute the size of the data segment in pages...
          if dataSize % PAGE_SIZE != 0
            print ("LoadExecutable: The data segment size not a multiple of page size\n")
            return -1
          endIf
          if dataStart != textStart + textSize
            print ("LoadExecutable: dataStart != textStart + textSize\n")
            return -1
          endIf
          dataSizeInPages = dataSize / PAGE_SIZE

          -- Compute the size of the bss segment in pages...
          if bssSize % PAGE_SIZE != 0
            print ("LoadExecutable: The bss segment size not a multiple of page size\n")
            return -1
          endIf
          if bssStart != dataStart + dataSize
            print ("LoadExecutable: bssStart != dataStart + dataSize\n")
            return -1
          endIf
          bssSizeInPages = bssSize / PAGE_SIZE

          -- Compute how many pages to put into the address space...
          i = textSizeInPages + dataSizeInPages + bssSizeInPages +
              USER_STACK_SIZE_IN_PAGES + NUMBER_OF_ENVIRONMENT_PAGES

          /*****          
          printIntVar ("NUMBER_OF_ENVIRONMENT_PAGES", NUMBER_OF_ENVIRONMENT_PAGES)
          printIntVar ("USER_STACK_SIZE_IN_PAGES", USER_STACK_SIZE_IN_PAGES)
          printIntVar ("textSizeInPages", textSizeInPages)
          printIntVar ("dataSizeInPages", dataSizeInPages)
          printIntVar ("bssSizeInPages", bssSizeInPages)
          printIntVar ("addrSpace.numberOfPages", addrSpace.numberOfPages)
          printIntVar ("Number of pages in this address space", i)
          printIntVar ("MAX_PAGES_PER_VIRT_SPACE", MAX_PAGES_PER_VIRT_SPACE)
          *****/

          -- Allocate the frames...
          if i > MAX_PAGES_PER_VIRT_SPACE
            print ("LoadExecutable: This virtual address space exceeds the limit\n")
            printIntVar ("LoadExecutable: Number of pages in this address space", i)
            printIntVar ("LoadExecutable: MAX_PAGES_PER_VIRT_SPACE", MAX_PAGES_PER_VIRT_SPACE)
            return -1
          endIf
          frameManager.GetNewFrames (addrSpace, i)

          --print ("LoadExecutable: The address space just allocated...\n")
          --addrSpace.Print ()

          -- Read and check the separator...
          if  self.ReadInt () != 0x2a2a2a2a
            print ("LoadExecutable: Invalid file format - missing separator (1)\n")
            frameManager.ReturnAllFrames (addrSpace)
            return -1
          endIf

          -- Read the text segment...
          nextVirtPage = textStart / PAGE_SIZE
          for i = 1 to textSizeInPages
            addr = addrSpace.ExtractFrameAddr (nextVirtPage)
            -- printIntVar ("About to read; nextVirtPage", nextVirtPage)
            -- printHexVar ("               addr", addr)
            if ! self.ReadBytes (addr, PAGE_SIZE)
              print ("LoadExecutable: Problems reading from file (text)\n")
              frameManager.ReturnAllFrames (addrSpace)
              return -1
            endIf
            addrSpace.ClearWritable (nextVirtPage)
            nextVirtPage = nextVirtPage + 1
          endFor

          -- Read and check the separator...
          if  self.ReadInt () != 0x2a2a2a2a
            print ("LoadExecutable: Invalid file format - missing separator (2)\n")
            frameManager.ReturnAllFrames (addrSpace)
            return -1
          endIf

          -- Read the data segment...
          for i = 1 to dataSizeInPages
            addr = addrSpace.ExtractFrameAddr (nextVirtPage)
            -- printIntVar ("About to read; nextVirtPage", nextVirtPage)
            -- printHexVar ("               addr", addr)
            if ! self.ReadBytes (addr, PAGE_SIZE)
              print ("LoadExecutable: Problems reading from file (text)\n")
              frameManager.ReturnAllFrames (addrSpace)
              return -1
            endIf
            nextVirtPage = nextVirtPage + 1
          endFor

          -- Read and check the separator...
          if  self.ReadInt () != 0x2a2a2a2a
            print ("LoadExecutable: Invalid file format - missing separator (3)\n")
            frameManager.ReturnAllFrames (addrSpace)
            return -1
          endIf

          -- Zero out the bss segment...
          addr = addrSpace.ExtractFrameAddr (nextVirtPage)
          -- printIntVar ("About to zero bss segment; page", nextVirtPage)
          -- printHexVar ("                           addr", addr)
          -- printHexVar ("                           bssSizeInBytes", bssSize)
          MemoryZero (addr, bssSize)

          -- User programs begin execution at the first word of the text segment...
          return textStart
        endMethod


      ----------  OpenFile . Lookup  ----------

      method Lookup ( filename: String)
     	     returns ptr to dirEntry
	  var ent: ptr to dirEntry

            if kind != DIRECTORY
	      FatalError ("Lookup on a non-Directory file.")
 	    endIf

	     -- Start at beginning
	     currentPos = 0
	     addPos = -1
	     ent = self.GetNextEntry(filename arraySize)
	     while ent != null
	        if StrCmp (filename, &ent.name) == 0
		   return ent
		endIf
		ent = self.GetNextEntry(filename arraySize)
	     endWhile
	     
	     -- Not found
	     return null
	endMethod

      ----------  OpenFile . GetNextEntry  ----------

      -- newSize -> used during lookup to keep a pointer
      -- to where an entry of newSize characters may be inserted

      method GetNextEntry (newSize: int) returns ptr to dirEntry
         var sec: int
	     offset: int
	     retVal: ptr to dirEntry

           if kind != DIRECTORY
	      FatalError ("GetNextEntry on a non-Directory file.")
	   endIf

	   sec = currentPos / PAGE_SIZE
	   offset = currentPos % PAGE_SIZE

	   if fcb.relativeSectorInBuffer != sec
	      -- print ("Need to load new sector!\n")
	      if !fcb.ReadSector(sec)
	        return null
	      endIf
	   endIf

	   -- Point to an entry in the buffer	   
	   retVal = (fcb.bufferPtr + offset) asPtrTo dirEntry

	   -- End of directory?
	   if retVal.inodeNum == -1
	     return null
	   endIf

	   -- End of Sector?
	   if retVal.inodeNum == 0

	     -- Can we save a new entry here?
	     if addPos == -1 && offset <= PAGE_SIZE - entSize(newSize)
	     	addPos = currentPos
	     endIf

	     -- Get Next sector
	     sec = sec + 1
	     offset = 0
	     currentPos = sec * PAGE_SIZE
	     
	     retVal = (fcb.bufferPtr + offset) asPtrTo dirEntry
	     if retVal.inodeNum == -1
	       return null
	     endIf

	   endIf

	   -- Update Current pointer
	   currentPos = currentPos + entSize(retVal.name arraySize)
	   
           return retVal
	endMethod

      ----------  OpenFile . AddEntry  ----------

      method AddEntry (inodeNum: int, filename: String) returns bool
        var 
	   ent: ptr to dirEntry
	   pi: ptr to int
	   sec: int
	   offset: int
	   save: int

	   -- Sanity check
           if kind != DIRECTORY
	      FatalError ("AddEntry on a non-Directory file.")
	   endIf

	   -- See if it exists already
	   ent = self.Lookup (filename)
	   if ent != null
	      print ("AddEntry: found name ") print(filename) nl()
	      return false
	   endIf

	   -- Check addPos ...
	   if addPos < 0
	      addPos = fcb.inode.fsize - 4
	   endIf

	   -- Now add the the entry, addPos should be set to
	   sec = addPos / PAGE_SIZE
	   offset = addPos % PAGE_SIZE
	   -- Make sure the correct sector is loaded
	   if fcb.relativeSectorInBuffer != sec
	      -- print ("Need to load new sector!\n")
	      if !fcb.ReadSector(sec)
	        return false
	      endIf
	   endIf

	   -- the location in the directory that the filename will fit
	   ent = (fcb.bufferPtr + offset) asPtrTo dirEntry
	   if ent.inodeNum != 0 && ent.inodeNum != -1
	      FatalError ("OpenFile.AddEntry incorrectly set addPos")
	   endIf

	   -- Special case: -1 and not enough room in the current
	   -- sector.
	   if ent.inodeNum == -1 && entSize(filename arraySize) > PAGE_SIZE - offset
	        -- don't use indirect block for directories ...
	        if sec == 9 || ! fcb.inode.AllocateNewSector(sec+1)
		   return false
		endIf
		fileSystem.fsLock.Lock()
	        ent.inodeNum = 0
		fcb.bufferIsDirty = true
		fcb.Flush()
		sec = sec + 1
		offset = 0
		MemoryZero (fcb.bufferPtr, PAGE_SIZE)
		ent = fcb.bufferPtr asPtrTo dirEntry
		ent.inodeNum = -1
		currentPos = (sec-1) * PAGE_SIZE
		fcb.inode.fsize = currentPos+4
		fcb.inode.dirty = true
		fcb.relativeSectorInBuffer = sec
		fileSystem.fsLock.Unlock()
	   endIf

	   -- Now add the new entry.
	   -- print ("AddEntry: ") print (filename) nl()
	   fileSystem.fsLock.Lock()
	   save = ent.inodeNum
	   ent.inodeNum = inodeNum
	   pi = ent asPtrTo int
	   *(pi+4) = filename arraySize
	   StrCopy(&ent.name, filename)
	   fcb.bufferIsDirty = true
	   offset = offset + entSize(filename arraySize)
	   ent = (fcb.bufferPtr + offset) asPtrTo dirEntry
	   ent.inodeNum = save
	   currentPos = currentPos + entSize(filename arraySize)
	   if currentPos+4 > fcb.inode.fsize
	      fcb.inode.fsize = currentPos+4
	      fcb.inode.dirty = true
	      fileSystem.fsLock.Unlock()
	      fcb.inode.WriteInode()
           else
	      fileSystem.fsLock.Unlock()
           endIf
	   
	   fcb.Flush()
           return true
	endMethod

  endBehavior

  
