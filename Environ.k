code Environ

  function getEnv (name: String) returns String
    var ix: int

      -- find the variable
      for ix = 0 to numEnv -1
        if env[ix].set && StrCmp (name, &env[ix].Name) == 0
	   return &env[ix].Value
	endIf
      endFor

      -- not found
      return null
    endFunction

  function setEnv (name: String, value: String) returns bool
    var ix: int

      -- Initialize it ...
      if numEnv == 0
	 *((&env) asPtrTo int) = MAX_ENVIRON
      endIf

      -- make sure there is no buffer overflow
      if value arraySize > MAX_STRING_LEN
         return false
      endIf

      -- Existing (or unset)
      for ix = 0 to numEnv -1
        if !env[ix].set || StrCmp (name, &env[ix].Name) == 0
	   if !env[ix].set 
	      *((&env[numEnv].Name) asPtrTo int) = name arraySize
	      StrCopy (&env[numEnv].Name, name)
	   endIf
	   *((&env[ix].Value) asPtrTo int) = value arraySize
	   StrCopy (&env[ix].Value, value)
	   env[ix].set = true
	   return true
	endIf
      endFor

      -- Define a new one
      if numEnv == MAX_ENVIRON
         return false
      endIf

      *((&env[numEnv].Name) asPtrTo int) = name arraySize
      StrCopy (&env[numEnv].Name, name)
      *((&env[numEnv].Value) asPtrTo int) = value arraySize
      StrCopy (&env[numEnv].Value, value)
      env[numEnv].set = true
      numEnv = numEnv + 1

      return true
    endFunction
  
  function unsetEnv (name: String)
    var ix: int

      -- find the variable
      for ix = 0 to numEnv -1
        if env[ix].set && StrCmp (name, &env[ix].Name) == 0
	   env[ix].set = false
	   return
	endIf
      endFor

    endFunction

endCode
