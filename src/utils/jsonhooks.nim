import jsony
import oids
import times

import ../models/[date, user]

proc parseHook*(s: string, i: var int, v: var DateTime) =
  var str: string
  parseHook(s, i, str)
  if str != "":
    v = parse(str, "yyyy-MM-dd'T'hh:mm:ssz")

proc dumpHook*(s: var string, v: DateTime) =
  if not v.isInitialized:
    s.add "null"
  else:
    s.add '"'
    s.add v.format("yyyy-MM-dd'T'hh:mm:ssz")
    s.add '"'

proc parseHook*(s: string, i: var int, v: var Oid) =
  var str: string
  parseHook(s, i, str)
  v = parseOid(str.cstring)

proc dumpHook*(s: var string, v: Oid) =
  s.add '"'
  s.add $v
  s.add '"'

proc parseHook*(s: string, i: var int, v: var Date) =
  var str: string
  parseHook(s, i, str)
  if str != "":
    v.val = parse(str, "yyyy-MM-dd", utc())

proc dumpHook*(s: var string, v: Date) =
  if not v.val.isInitialized:
    s.add "null"
  else:
    s.add '"'
    s.add v.val.getDateStr
    s.add '"'

proc dumpHook*(s: var string, v: AggregateUserWithPassword) = dumpHook(s, AggregateUser(v))
proc dumpHook*(s: var string, v: UserWithPassword) = dumpHook(s, User(v))
