import mongo
import mongo/clientbase
import oids
import times

import ../models/movie
import ../utils/[mongoutils]
import ../errors/exceptions
import ../routes/interfaces

type
  WatchlistService* = ref object
    wlCol*: Collection[Mongo]

proc newWatchlistService*(db: Database[Mongo]) : WatchlistService {.inline.} = WatchlistService(wlCol: db["watchlists"])

proc addMovieToUserWatchList*(w: WatchlistService, ctx: ContextLogger, user, movie: Oid) =
  mixin info
  ctx.info "MovieService::updateMovie", "User", $user, "Movie", $movie
  # save watch list data in documents with movie_ids field with length of at most `100`
  # better way to enforce this would be to create a schema validator for this collection see <https://docs.mongodb.com/manual/core/schema-validation/>
  discard w.wlCol.findAndModify(%*{"user_id": user, "movie_ids.99": {"$exists": false}}, nil, %*{"$addToSet": {"movie_ids": movie}}, true, true).parseFindAndModify(Movie)

proc removeMovieFromUserWatchList*(w: WatchlistService, ctx: ContextLogger, user, movie: Oid) =
  mixin info
  ctx.info "MovieService::updateMovie", "User", $user, "Movie", $movie
  discard w.wlCol.findAndModify(%*{"user_id": user, "movie_ids": movie}, nil, %*{"$pull": {"movie_ids": movie}}, true, true).parseFindAndModify(Movie)

proc getUserWatchlist*(w: WatchlistService, ctx: ContextLogger, user: Oid, page, limit: int, categories: seq[Oid] = @[]) : AggregateMoviesAndCount =
  mixin info
  var filter = %*{}
  if categories.len > 0:
    filter["category_ids"] = %*{"$in": categories}
  let res = w.wlCol.db["$cmd"].makeQuery(%*{
    "aggregate": w.wlCol.name,
    "pipeline": [
      {"$match": {"user_id": user}},
      {"$unwind": "$movie_ids"},
      {
        "$lookup": {
          "from": "movies",
          "localField": "movie_ids",
          "foreignField": "_id",
          "as": "movies"
        }
      },
      {"$project": {"_id": false, "movies": true}},
      {"$replaceRoot": {"newRoot": "$movies"}},
      {"$match": filter},
      {
        "$lookup": {
          "from": "categories",
          "localField": "category_ids",
          "foreignField": "_id",
          "as": "categories"
        }
      },
      {
        "$facet": {
          "movies": [
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
  let data = res.bson["cursor"]["firstBatch"].to(seq[AggregateMoviesAndCount])
  result = if data.len == 0: AggregateMoviesAndCount() else: data[0]
