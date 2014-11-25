--
--  Environment Library
--
--     Phil Nelson, Spring 2013
--

header Environ

  uses UserSystem

  const MAX_ENVIRON = 25
  const MAX_STRING_LEN = 255
  const MAX_KEY_LEN = 50

  type
      envDefn = record
         set: bool
 	Name: array [ MAX_KEY_LEN ] of char
       Value: array [ MAX_STRING_LEN ] of char
      endRecord

  var
      env: array [ MAX_ENVIRON ] of envDefn
   numEnv: int

functions

  getEnv (name: String) returns String
  setEnv (name: String, value: String) returns bool
  unsetEnv (name: String)

endHeader


