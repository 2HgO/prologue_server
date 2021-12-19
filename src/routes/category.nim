import jsony
import mongo except `%*`
from oids import `$`, parseOid
from prologue import getQueryParams, Context, async, getPathParams, body, newFuture, resp, `$`, Http201
from strutils import parseInt

import ../errors/exceptions
import ../models/category as category_models
import ../services/category as category_service
import ../utils/[jsonhooks, mongoutils]

import context

proc createCategory*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can create a category")
  ctx.info "Handler::createCategory", "Request", ctx.request.body
  var req = fromJson(ctx.request.body, Category)
  ctx.catSvc.createCategory(ctx, req)
  resp req.toJson, Http201

proc getCategories*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::getCategories", "Request", ctx.request.queryParams
  let limit = ctx.getQueryParams("limit", "20").parseInt.int32
  let page = ctx.getQueryParams("page", "1").parseInt.int32
  if limit == 0: raiseValidationError("limit cannot be less that 1")
  if page == 0: raiseValidationError("page cannot be less that 1")

  let r = ctx.catSvc.getCategories(ctx, page, limit)
  resp r.toJson

proc getCategory*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  ctx.info "Handler::getCategory", "CategoryID", ctx.getPathParams("categoryID")
  validateOid ctx.getPathParams("categoryID")
  let id = parseOid ctx.getPathParams("categoryID").cstring
  let category = ctx.catSvc.getCategory(ctx, id)
  resp category.toJson

proc deleteCategory*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can update a category")
  ctx.info "Handler::deleteCategory", "CategoryID", ctx.getPathParams("categoryID")
  validateOid ctx.getPathParams("categoryID")
  let id = parseOid ctx.getPathParams("categoryID").cstring
  let category = ctx.catSvc.deleteCategory(ctx, id)
  resp category.toJson

proc updateCategory*(ctx: Context) {.async, gcsafe.} =
  let ctx: ReqContext = ReqContext(ctx)
  if ctx.aud != "prologue:ADMIN": raiseAuthorizationError("only admins can update a category")
  ctx.info "Handler::updateCategory", "CategoryID", ctx.getPathParams("categoryID"), "Request", ctx.request.body
  validateOid ctx.getPathParams("categoryID")
  let id = parseOid ctx.getPathParams("categoryID").cstring
  let req = fromJson(ctx.request.body, UpdateCategoryRequest)
  let category = ctx.catSvc.updateCategory(ctx, id, req)
  resp category.toJson
