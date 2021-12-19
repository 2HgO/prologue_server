import oids
import mongo
import times

import ./base
import ./date
import ./category
import ../errors/exceptions

type
  Movie* = object of DocBase
    name*: string
    category_ids*: seq[Oid]
    release*: Date
  AggregateMovie* = object of Movie
    categories*: seq[Category]
  AggregateMoviesAndCount* = object
    movies*: seq[AggregateMovie]
    count*: uint64
  UpdateMovieRequest* = object
    category_ids*{.omitempty.}: seq[Oid]

proc postHook*(v: var Movie) =
  if v.name == "": raiseValidationError "Name is required"
  if not v.release.val.isInitialized: raiseValidationError "Release date is required"
