import mongo

import ./base
import ../errors/exceptions

type
  Category* = object of DocBase
    name*: string
    icon*: string
  CategoriesAndCount* = object
    categories*: seq[Category]
    count*: uint64
  UpdateCategoryRequest* = object
    icon*{.omitempty.}: string

proc postHook*(v: var Category) =
  if v.name == "": raiseValidationError "Name is required"
