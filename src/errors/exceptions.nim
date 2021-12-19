import prologue

type
  HttpError* = object of CatchableError
    status_code*: HttpCode
  ValidationError* = object of HttpError
  AuthorizationError* = object of HttpError
  NotFoundError* = object of HttpError
  NotAllowedError* = object of HttpError
  ConflictError* = object of HttpError
  GoneError* = object of HttpError
  FatalError* = object of HttpError

proc raiseHttpError*[T: HttpError](msg: string, status_code: HttpCode) {.noReturn.} =
  let e = new(T)
  e.msg = msg
  e.status_code = status_code
  raise e

proc raiseValidationError*(msg: string) {.noReturn, inline.} =
  raiseHttpError[ValidationError](msg, Http400)

proc raiseAuthorizationError*(msg: string) {.noReturn, inline.} =
  raiseHttpError[AuthorizationError](msg, Http401)

proc raiseNotFoundError*(msg: string) {.noReturn, inline.} =
  raiseHttpError[NotFoundError](msg, Http404)

proc raiseNotAllowedError*(msg: string) {.noReturn, inline.} =
  raiseHttpError[NotAllowedError](msg, Http405)

proc raiseConflictError*(msg: string) {.noReturn, inline.} =
  raiseHttpError[ConflictError](msg, Http409)

proc raiseGoneError*(msg: string) {.noReturn, inline.} =
  raiseHttpError[GoneError](msg, Http410)

proc raiseFatalError*(msg: string) {.noReturn, inline.} =
  raiseHttpError[FatalError](msg, Http500)
