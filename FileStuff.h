  -----------------------------  DiskDriver  ---------------------------------
  --
  --  There is only one instance of this class.
  --
  class DiskDriver
    superclass Object
    fields
      DISK_STATUS_WORD_ADDRESS: ptr to int
      DISK_COMMAND_WORD_ADDRESS: ptr to int
      DISK_MEMORY_ADDRESS_REGISTER: ptr to int
      DISK_SECTOR_NUMBER_REGISTER: ptr to int
      DISK_SECTOR_COUNT_REGISTER: ptr to int
      semToSignalOnCompletion: ptr to Semaphore
      semUsedInSynchMethods: Semaphore
      diskBusy: Mutex
    methods
      Init ()
      SynchReadSector  (sectorAddr, numberOfSectors, memoryAddr: int)
      StartReadSector  (sectorAddr, numberOfSectors, memoryAddr: int,
                        whoCares: ptr to Semaphore)
      SynchWriteSector (sectorAddr, numberOfSectors, memoryAddr: int)
      StartWriteSector (sectorAddr, numberOfSectors, memoryAddr: int,
                        whoCares: ptr to Semaphore)
  endClass

   -----------------------------  FileManager  ---------------------------------

  class FileManager
    superclass Object
    fields
      fileManagerLock: Mutex
      fcbTable: array [MAX_NUMBER_OF_FILE_CONTROL_BLOCKS] of FileControlBlock
      anFCBBecameFree: Condition
      fcbFreeList: List [FileControlBlock]
      openFileTable: array [MAX_NUMBER_OF_OPEN_FILES] of OpenFile
      anOpenFileBecameFree: Condition
      openFileFreeList: List [OpenFile]
      serialTerminalFile: OpenFile

    methods
      Init ()
      Print ()
      LookupFCB (inodeNum: int) returns ptr to FileControlBlock
      GetFCB ( inodeNum: int) returns ptr to FileControlBlock  -- null if errors
      GetAnOpenFile (block: bool) returns ptr to OpenFile

      -- Open returns null if errors
      Open (filename: String, dir: ptr to OpenFile, flags, mode: int) returns ptr to OpenFile
      Close (open: ptr to OpenFile)
      SynchRead (open: ptr to OpenFile, targetAddr, bytePos, numBytes: int) returns bool
      SynchWrite (open: ptr to OpenFile, sourceAddr, bytePos, numBytes: int) returns bool
 
 endClass

  -----------------------------  ToyFs   --------------------------------

  class ToyFs
  superclass Object

    fields
    
      rootDirectory: ptr to OpenFile
      inodeBuffer: int  -- address of a frame
      inodeBuffSec: int  -- sector address contents 
      fsLock: Mutex

    -- Super Block / Root 
      superBlock: int
      numInodes: int
      fssize: int
      i_bitmap: BitMap
      d_bitmap: BitMap
      dataSecOffset: int
      
    methods
      Init()  -- Loads the super block
      SaveSuper()  --  Saves the super block back to disk

      -- Helper methods
      OpenLastDir (filename: String, startDir: ptr to OpenFile, lastElIndex: ptr to int) returns ptr to OpenFile
      NameToInodeNum (filename: String, dir : ptr to OpenFile) returns int

      AllocInode () returns int
      FreeInode (iNum: int)

      AllocDataBlock () returns int
      FreeDataBlock (dbNum: int)

      -- Routines for implementing ToyFs parts of system calls

      ReadFile (file: ptr to OpenFile, userBuffer: ptr to char,
      	        sizeInBytes: int) returns int
      WriteFile (file: ptr to OpenFile, userBuffer: ptr to char,
      		sizeInBytes: int) returns int

      CreateFile (filename: String, mode: int) returns int

      MakeDir (dirname: String) returns int
      RemoveDir (dirname: String) returns int
      
      Link (oldname, newname: String) returns int
      Unlink (filename: String) returns int

  endClass

  -----------------------------  InodeData   --------------------------------

  type diskInode = record
       		      nlinksAndMode: int
		      fsize: int
		      balloc: int
		      direct: array [10] of int
		      indir1: int
		      indir2: int
		    endRecord

  class InodeData
  superclass Object
    fields
      number : int
      nlinks : int
      mode   : int
      fsize  : int  -- locgical file size in bytes
      balloc : int  -- blocks allocated including indirect blocks
      direct : array [10] of int
      indir1 : int  -- 1st indirect block pointer
      indir2 : int  -- 2nd indirect block pointer
      dirty  : bool -- has anything changed
      indSec : int   -- pointer to a frame with indirect pointers.
      

    methods
      Init ()
      Print ()

      GetInode ( num : int )
      WriteInode ()
      
      GetDataSectorNumber ( logicalSector: int ) returns int
      AllocateNewSector ( logicalSector: int) returns bool
      GetIndirect ()
      FreeIndirect ()
      SaveIndirect ()

      SetMode ( newMode: int )

    endClass

 -----------------------------  FileControlBlock  ---------------------------------

  class FileControlBlock
    superclass Listable
    fields
      inode: InodeData
      numberOfUsers: int             -- count of OpenFiles pointing here
      bufferPtr: int                 -- addr of a page frame
      relativeSectorInBuffer: int    -- or -1 if none
      bufferIsDirty: bool            -- Set to true when buffer is modified
    methods
      Init ()
      Print ()
      ReadSector (newSector: int) returns bool
      Flush ()
      Release (lock: ptr to Mutex)
      
    endClass

  -----------------------------  OpenFile  ---------------------------------

  class OpenFile
    superclass Listable
    fields
      kind: int                      -- FILE, TERMINAL, PIPE, or  DIRECTORY
      currentPos: int                -- 0 = first byte of file
      fcb: ptr to FileControlBlock   -- null = not open
      numberOfUsers: int             -- count of Processes pointing here
      addPos: int    		     -- byte in directory to add last failed lookup
    methods
      Print ()
      Init (fKind: int, fFcb: ptr to FileControlBlock)

      -- Returns a new reference to self and increments numberOfUsers
      NewReference () returns ptr to OpenFile

      -- General Operations
      ReadInt () returns int
     
      -- Read bytes to Kernel Address of targetAddr
      ReadBytes (targetAddr, numBytes: int) returns bool        -- true=All Okay

      -- Executables
      LoadExecutable (addrSpace: ptr to AddrSpace) returns int  -- -1 = problems

      -- Directory Operations
      Lookup ( filename: String) returns ptr to dirEntry
      GetNextEntry (newSize: int) returns ptr to dirEntry

      -- AddEntry returns true if entry is added
      AddEntry (inodeNum: int, filename: String) returns bool


  endClass

