import mongo
import oids

import ./base
import ./category
import ./date
import ./role

import ../errors/exceptions

type
  User* = object of DocBase
    fname*: string
    lname*: string
    email*: string
    dob*: Date
    role*: Role
    like_ids*: seq[Oid]
  UpdateUserRequest* = object
    fname*{.omitempty.}: string
    lname*{.omitempty.}: string
    like_ids*{.omitempty.}: seq[Oid]
  UserWithPassword* = object of User
    password*: string
  AggregateUser* = object of User
    likes*: seq[Category]
  AggregateUserWithPassword* = object of AggregateUser
    password*: string
  UserAndToken* = object
    user*: AggregateUserWithPassword
    token*: string
  EmailAndPassword* = object
    email*: string
    password*: string
  AggregateUserAndCount* = object
    users*: seq[AggregateUser]
    count*: uint64

proc postHook*(v: var UserWithPassword) =
  if v.fname == "": raiseValidationError "First name is required"
  if v.lname == "": raiseValidationError "Last name is required"
  if v.email == "": raiseValidationError "Email is required"

proc postHook*(v: var EmailAndPassword) =
  if v.password == "": raiseValidationError "Password is required"
  if v.email == "": raiseValidationError "Email is required"
