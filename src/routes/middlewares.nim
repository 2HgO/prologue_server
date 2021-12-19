import prologue
import prologue/middlewares/cors
import jsony
import oids
import jwt
import mongo

import context
from ../services/user as user_service import getUser
from ../models/user as user_models import AggregateUser
import ../utils/mongoutils
import ../errors/exceptions as internal_errors
import ../config/env

let logHandler*: HandlerAsync = proc(ctx: Context) {.async, gcsafe.} =
  try:
    await switch(ctx)
  finally:
    ReqContext(ctx).info ctx.request.path, "response_code", ctx.response.code

let errorHandler*: HandlerAsync = proc(ctx: Context) {.async.} =
  type httpErrResp = object
    success: bool
    message: string
  try:
    await switch(ctx)
  except AssertionDefect:
    resp jsony.toJson(httpErrResp(success: false, message: getCurrentExceptionMsg())), Http400
  except InvalidToken:
    resp jsony.toJson(httpErrResp(success: false, message: getCurrentExceptionMsg())), Http401
  except internal_errors.HttpError as e:
    resp jsony.toJson(httpErrResp(success: false, message: e.msg)), e.status_code

let setHeaders*: HandlerAsync = proc(ctx: Context) {.async.} = 
  ctx.response.setHeader("content-type", "application/json")
  ctx.response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
  ctx.response.setHeader("Access-Control-Allow-Credentials", "true")
  ctx.response.setHeader("server", "prologue-server")
  await switch(ctx)

let corsHandler*: HandlerAsync = CorsMiddleware(allowOrigins = @["*"], allowMethods = @["*"], allowHeaders= @["*"])

let validateToken*: HandlerAsync = proc(ctx: Context) {.async, gcsafe.} =
  var token: string = ctx.request.getHeaderOrDefault("authorization")[0]
  if token.len < 8: raiseAuthorizationError("no auhtorization token")
  token = token[7..^1]
  let jwtToken = toJWT(token)
  if not jwtToken.verify(JWT_PUB, RS256):
    raiseAuthorizationError("invalid auhtorization token")
  jwtToken.verifyTimeClaims()
  validateOid jwtToken.claims.getOrDefault("uid").node.getStr()
  let uid = parseOid jwtToken.claims.getOrDefault("uid").node.getStr().cstring
  new(ReqContext(ctx).usr)
  ReqContext(ctx).usr[] = ReqContext(ctx).userSvc.getUser(ReqContext(ctx), uid)
  ReqContext(ctx).aud = jwtToken.claims.getOrDefault("aud").node.getStr()
  await switch(ctx)

proc handleRoute404*(ctx: Context) {.async.} =
  resp """{"success": false, "message": "route and method combination not found"}""", Http404

proc handleRoute500*(ctx: Context) {.async.} =
  resp """{"success": false, "message": "Opps! an error occured"}""", Http500

