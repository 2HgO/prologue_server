import mongo
import mongo/clientbase
import uri

import ../config/env

var DBCon : Database[Mongo]

proc initDB*() : Database[Mongo] =
  once:
    let con = newMongoWithURI(parseUri(DB_URL))
    doAssert con.connect
    DBCon = con[DB_NAME]
  result = DBCon

proc createIndexes*(db: Database[Mongo]) =
  once:
    discard db["$cmd"].makeQuery(%*{
      "createIndexes": "users",
      "indexes": [
        {
          "key": {
            "email": 1
          },
          "name": "unique_user_email_idx",
          "unique": true,
        }
      ]
    }).first.toStatusReply
    discard db["$cmd"].makeQuery(%*{
      "createIndexes": "categories",
      "indexes": [
        {
          "key": {
            "name": 1
          },
          "name": "unique_category_name_idx",
          "unique": true,
        }
      ]
    }).first.toStatusReply
    discard db["$cmd"].makeQuery(%*{
      "createIndexes": "movies",
      "indexes": [
        {
          "key": {
            "name": 1
          },
          "name": "unique_movie_name_idx",
          "unique": true,
        }
      ]
    }).first.toStatusReply
    discard db["$cmd"].makeQuery(%*{
      "createIndexes": "watchlists",
      "indexes": [
        {
          "key": {
            "user_id": 1,
            "movie_ids": 1,
          },
          "name": "unique_user_and_movie_entry_idx",
          "unique": true,
        }
      ]
    }).first.toStatusReply
