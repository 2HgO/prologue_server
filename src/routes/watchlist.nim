import jsony
import mongo except `%*`
from oids import `$`, parseOid, Oid
from prologue import getQueryParams, Context, async, getPathParams, body, newFuture, resp, `$`
from strutils import parseInt, split
import sequtils

import ../errors/exceptions
import ../models/movie as movie_models
import ../services/watchlist as watchlist_service
import ../utils/[mongoutils]

import context

proc addMovieToUserWatchList*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::addMovieToUserWatchList", "UserID", $ctx.usr.id, "MovieID", ctx.getPathParams("movieID")
  validateOid ctx.getPathParams("movieID")
  let id = parseOid ctx.getPathParams("movieID").cstring
  ctx.wlSvc.addMovieToUserWatchList(ctx, ctx.usr.id, id)
  resp {"success": true}.toJson

proc removeMovieFromUserWatchList*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::removeMovieFromUserWatchList", "UserID", $ctx.usr.id, "MovieID", ctx.getPathParams("movieID")
  validateOid ctx.getPathParams("movieID")
  let id = parseOid ctx.getPathParams("movieID").cstring
  ctx.wlSvc.removeMovieFromUserWatchList(ctx, ctx.usr.id, id)
  resp {"success": true}.toJson

proc getUserWatchlist*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  var uid = ctx.usr.id
  if ctx.getPathParams("userID") != "" and ctx.getPathParams("userID") != $uid:
    if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can view another user's watchlist")
    validateOid ctx.getPathParams("userID")
    uid = parseOid ctx.getPathParams("userID").cstring
  ctx.info "Handler::getUserWatchlist", "UserID", $uid, "Request", ctx.request.queryParams
  let limit = ctx.getQueryParams("limit", "20").parseInt.int32
  let page = ctx.getQueryParams("page", "1").parseInt.int32
  let categories = map(ctx.getQueryParams("categories").split('|').deduplicate, proc(s: string) : Oid =
    validateOid s
    result = parseOid(s)  
  )
  if limit == 0: raiseValidationError("limit cannot be less that 1")
  if page == 0: raiseValidationError("page cannot be less that 1")
  let res = ctx.wlSvc.getUserWatchlist(ctx, uid, page, limit, categories)
  resp res.toJson
