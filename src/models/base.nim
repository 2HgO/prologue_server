import mongo
import oids
import times

type
  DocBase* {.inheritable.} = object 
    id*{.dbKey: "_id", omitempty.}: Oid
    created_at*{.omitempty.}: DateTime
    updated_at*{.omitempty.}: DateTime
