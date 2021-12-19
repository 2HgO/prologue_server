import jsony
import mongo except `%*`
from oids import `$`, parseOid, Oid
from prologue import getQueryParams, Context, async, getPathParams, body, newFuture, resp, `$`, Http201
from strutils import parseInt, split
import sequtils

import ../errors/exceptions
import ../models/movie as movie_models
import ../services/movie as movie_service
import ../utils/[jsonhooks, mongoutils]

import context

proc createMovie*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can create a movie")
  ctx.info "Handler::createMovie", "Request", ctx.request.body
  var req = fromJson(ctx.request.body, Movie)
  ctx.movSvc.createMovie(ctx, req)
  resp req.toJson, Http201

proc getMovies*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::getMovies", "Request", ctx.request.queryParams
  let limit = ctx.getQueryParams("limit", "20").parseInt.int32
  let page = ctx.getQueryParams("page", "1").parseInt.int32
  let categories = map(ctx.getQueryParams("categories").split('|').deduplicate, proc(s: string) : Oid =
    validateOid s
    result = parseOid(s)  
  )
  if limit == 0: raiseValidationError("limit cannot be less that 1")
  if page == 0: raiseValidationError("page cannot be less that 1")

  let r = ctx.movSvc.getMovies(ctx, page, limit, categories)
  resp r.toJson

proc getMovie*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::getMovie", "MovieID", ctx.getPathParams("movieID")
  validateOid ctx.getPathParams("movieID")
  let id = parseOid ctx.getPathParams("movieID").cstring
  let movie = ctx.movSvc.getMovie(ctx, id)
  resp movie.toJson

proc deleteMovie*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can delete a movie")
  ctx.info "Handler::deleteMovie", "MovieID", ctx.getPathParams("movieID")
  validateOid ctx.getPathParams("movieID")
  let id = parseOid ctx.getPathParams("movieID").cstring
  let movie = ctx.movSvc.deleteMovie(ctx, id)
  resp movie.toJson

proc updateMovie*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can update a movie")
  ctx.info "Handler::updateMovie", "MovieID", ctx.getPathParams("movieID"), "Request", ctx.request.body
  validateOid ctx.getPathParams("movieID")
  let id = parseOid ctx.getPathParams("movieID").cstring
  let req = fromJson(ctx.request.body, UpdateMovieRequest)
  let movie = ctx.movSvc.updateMovie(ctx, id, req)
  resp movie.toJson
