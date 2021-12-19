import bcrypt
import mongo
import mongo/clientbase
import oids
from strutils import toLowerAscii
import times

import ../models/user
import ../utils/[bcryptutils, mongoutils]
import ../errors/exceptions
import ../routes/interfaces

type
  UserService* = ref object
    userCol*: Collection[Mongo]
    wlCol: Collection[Mongo]

proc newUserService*(db: Database[Mongo]) : UserService {.inline.} = UserService(userCol: db["users"], wlCol: db["watchlists"])

proc createUser*(u: UserService, c: ContextLogger, user: var UserWithPassword) =
  mixin info
  c.info "UserService::createUser", "UserEmail", user.email
  user.email = toLowerAscii(user.email)
  user.password = hash(user.password, genSalt())
  user.created_at = now()
  user.updated_at = user.created_at
  let res = u.userCol.insert(%*user)
  if res.inserted_ids.len == 0:
    echo res.err
    raiseFatalError("Opps! something unexpected happened")
  user.id = res.inserted_ids[0].to(Oid)
  c.info "UserService::createUser", "UserID", $user.id

proc updateUser*(u: UserService, c: ContextLogger, id: Oid, req: UpdateUserRequest) : User =
  mixin info
  c.info "UserService::updateUser", "UserID", $id, "Update", $req
  result = u.userCol.findAndModify(%*{"_id": id}, nil, %*{"$set": req}, true, false).parseFindAndModify(User)

proc deleteUser*(u: UserService, c: ContextLogger, id: Oid) =
  mixin info
  c.info "UserService::deleteUser", "UserID", $id
  u.userCol.remove(%*{"_id": id}, 1).parseRemove(User, true)
  discard u.wlCol.remove(%*{"user_id": id}) # do nothing if command fails

proc getUsers*(u: UserService, c: ContextLogger, page, limit: int) : AggregateUserAndCount =
  mixin info
  c.info "UserService::getUsers", "Page", page, "Limit", limit
  let res = u.userCol.db["$cmd"].makeQuery(%*{
    "aggregate": u.userCol.name,
    "pipeline": [
      {
        "$lookup": {
          "from": "categories",
          "localField": "like_ids",
          "foreignField": "_id",
          "as": "likes"
        }
      },
      {
        "$facet": {
          "users": [
            {"$skip": (page - 1) * limit},
            {"$limit": limit},
          ],
          "count": [{"$count": "total"}]
        }
      },
      {
        "$addFields": {
          "count": {"$ifNull": [{"$first": "$count.total"}, 0]}
        }
      }
    ],
    "allowDiskUse": true,
    "cursor": {"batchSize": 1},
  }).limit(1).first.toStatusReply
  if not res.ok:
    echo res.err
    raiseFatalError("Opps! something unexpected happened")
  let data = res.bson["cursor"]["firstBatch"].to(seq[AggregateUserAndCount])
  result = if data.len == 0: AggregateUserAndCount() else: data[0]

proc getUserImpl[T: User](u: UserService, filter: Bson) : T =
  let res = u.userCol.db["$cmd"].makeQuery(%*{
    "aggregate": u.userCol.name,
    "pipeline": [
      {"$match": filter},
      {"$limit": 1},
      {
        "$lookup": {
          "from": "categories",
          "localField": "like_ids",
          "foreignField": "_id",
          "as": "likes"
        }
      },
    ],
    "allowDiskUse": true,
    "cursor": {"batchSize": 1},
  }).limit(1).first.toStatusReply
  if not res.ok:
    echo res.err
    raiseFatalError("Opps! something unexpected happened")
  let data = res.bson["cursor"]["firstBatch"].to seq[T]
  if data.len != 1: raiseNotFoundError("user not found")
  result = data[0]

proc getUser*(u: UserService, c: ContextLogger, id: Oid) : AggregateUser =
  mixin info
  c.info "UserService::getUser", "UserID", $id
  result = getUserImpl[AggregateUser](u, %*{"_id": id})

proc getUser*(u: UserService, c: ContextLogger, email: string) : AggregateUserWithPassword =
  mixin info
  c.info "UserService::getUser", "UserEmail", email
  result = getUserImpl[AggregateUserWithPassword](u, %*{"email": email})
