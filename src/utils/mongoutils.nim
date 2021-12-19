import mongo

from strutils import toLowerAscii
import times
import typetraits
import re

import ../errors/exceptions
import ../models/date

let oidRe = re"^[0-9A-Fa-f]{24}$"

proc validateOid*(s: string) =
  if not s.match(oidRe):
    raiseValidationError("invalid object id provided")

proc to*(b: Bson, d: var Date) {.inline.} =
  d.val = b.to(DateTime)

proc toBson*(d: Date) : Bson {.inline.} =
  result = d.val.toBson

template checkErrorObject(s: StatusReply, t: typedesc, extrachecks: untyped) =
  if not s.ok or s.err != "":
    if s.bson["lastErrorObject"]["code"].to(int) == 11000:
      raiseConflictError("duplicate " & typetraits.name(T).toLowerAscii)
    raiseFatalError(s.err)
  extrachecks

proc parseFindAndModify*[T](s: StatusReply, _: typedesc[T]) : T =
  checkErrorObject(s, T):
    if "lastErrorObject" in s.bson:
      if s.bson["lastErrorObject"]["n"].to(int) == 0:
        raiseNotFoundError(typetraits.name(T).toLowerAscii & " not found")
  result = s.bson["value"].to(T)

proc parseRemove*[T](s: StatusReply, _: typedesc[T], mustDelete: bool = true) : int {.discardable.} =
  result = s.n
  checkErrorObject(s, T):
    if result == 0 and mustDelete:
      raiseNotFoundError(typetraits.name(T).toLowerAscii & " not found")
