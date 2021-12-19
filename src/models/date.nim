import times

type
  Date* = object
    val: DateTime

proc `$`*(d: Date) : string {.inline.} =
  if d.val.isInitialized: result = "null"
  else: result = d.val.getDateStr
proc `val`*(d: Date) : DateTime {.inline.} = d.val
proc `val=`*(d: var Date, dt: DateTime) {.inline.} = d.val = dt
