import prologue
import oids
import morelogging

import ../db/db
import ../services/[category, movie, user, watchlist]
from ../models/user as user_models import AggregateUser

let t = newStdoutLogger(fmtStr="$time ")

type
  ReqContext* = ref object of Context
    userSvc*: UserService
    catSvc*: CategoryService
    movSvc*: MovieService
    wlSvc*: WatchlistService
    usr*: ref AggregateUser
    reqID*: string
    aud*: string

let catSvc = newCategoryService(initDB())
let movSvc = newMovieService(initDB())
let userSvc = newUserService(initDB())
let wlSvc = newWatchlistService(initDB())

proc init*(ctx: ReqContext) =
  ctx.catSvc = catSvc
  ctx.movSvc = movSvc
  ctx.userSvc = userSvc
  ctx.wlSvc = wlSvc
  ctx.reqID = $genOid()
  ctx.response.setHeader("x-request-id", ctx.reqID)

method extend*(ctx: ReqContext) =
  init(ctx)

# TODO: improve logger
proc info*(ctx: ReqContext, msg: string, data: varargs[string, `$`]) =
  doAssert (data.len and 1) == 0
  var r: seq[(string, string)] = @[("RequestID", ctx.reqID)]
  for i in countup(0, high(data), 2): r.add (data[i], data[i+1])
  t.info msg, r
proc debug*(ctx: ReqContext, msg: string, data: varargs[string, `$`]) =
  doAssert (data.len and 1) == 0
  var r: seq[(string, string)] = @[("RequestID", ctx.reqID)]
  for i in countup(0, high(data), 2): r.add (data[i], data[i+1])
  t.debug msg, r
proc error*(ctx: ReqContext, msg: string, data: varargs[string, `$`]) =
  doAssert (data.len and 1) == 0
  var r: seq[(string, string)] = @[("RequestID", ctx.reqID)]
  for i in countup(0, high(data), 2): r.add (data[i], data[i+1])
  t.error msg, r
