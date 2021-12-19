from json import `%*`
import jsony
from jwt import initJWT, JOSEHeader, toClaims, sign, RS256, `$`
import mongo except `%*`
from oids import `$`, parseOid
from prologue import getQueryParams, Context, async, getPathParams, body, newFuture, resp, `$`, Http201
from strutils import parseInt
from times import epochTime

from ../config/env import JWT_KEY
import ../errors/exceptions
import ../models/user as user_models
import ../services/user as user_service
import ../utils/[jsonhooks, bcryptutils, mongoutils]

import context

proc createUser*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::createUser", "Request", ctx.request.body
  var req = fromJson(ctx.request.body, UserWithPassword)
  ctx.userSvc.createUser(ctx, req)
  resp req.toJson, Http201

proc login*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  let req = fromJson(ctx.request.body, EmailAndPassword)
  let user = ctx.userSvc.getUser(ctx, req.email)
  if not compareHashAndPassword(cast[seq[byte]](user.password), cast[seq[byte]](req.password)): raiseValidationError("invalid credentials provided")

  var token = initJWT(
    header = JOSEHeader(alg: RS256, typ: "JWT"),
    claims = toClaims(%*{
      "iss": "eseosala:inflow",
      "aud": "prologue:" & $user.role,
      "exp": int(epochTime() + 60 * 60 * 24 * 3),
      "iat": int(epochTime()),
      "uid": $user.id,
      "email": user.email,
      "name": (user.fname & " " & user.lname),
    }),
  )
  token.sign(JWT_KEY)
  resp UserAndToken(user: user, token: $token).toJson

proc getUsers*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can view users list")
  ctx.info "Handler::getUsers", "Request", ctx.request.queryParams
  let limit = ctx.getQueryParams("limit", "20").parseInt
  let page = ctx.getQueryParams("page", "1").parseInt
  if limit == 0: raiseValidationError("limit cannot be less that 1")
  if page == 0: raiseValidationError("page cannot be less that 1")

  let r = ctx.userSvc.getUsers(ctx, page, limit)
  resp r.toJson

proc getUser*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::getUser", "UserID", $ctx.usr.id
  resp ctx.usr.toJson

proc deleteUser*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::deleteUser", "UserID", $ctx.usr.id
  ctx.userSvc.deleteUser(ctx, ctx.usr.id)
  resp ctx.usr.toJson

proc updateUser*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::deleteUser", "UserID", $ctx.usr.id, "Request", ctx.request.body
  let req = fromJson(ctx.request.body, UpdateUserRequest)
  let user = ctx.userSvc.updateUser(ctx, ctx.usr.id, req)
  resp user.toJson
