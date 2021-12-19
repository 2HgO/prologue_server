import mongo
import mongo/clientbase
import oids
import times

import ../models/movie
import ../utils/[mongoutils]
import ../errors/exceptions
import ../routes/interfaces

type
  MovieService* = ref object
    movCol*: Collection[Mongo]
    wlCol: Collection[Mongo]

proc newMovieService*(db: Database[Mongo]) : MovieService {.inline.} = MovieService(movCol: db["movies"], wlCol: db["watchlists"])

proc createMovie*(m: MovieService, ctx: ContextLogger, movie: var Movie) =
  mixin info
  movie.created_at = now()
  movie.updated_at = movie.created_at
  let res = m.movCol.insert(%*movie)
  if res.inserted_ids.len == 0:
    echo res.err
    raiseFatalError("an error occured")
  movie.id = res.inserted_ids[0].to(Oid)

proc getMovie*(m: MovieService, ctx: ContextLogger, id: Oid) : AggregateMovie =
  mixin info
  ctx.info "UserService::getMovie", "MovieID", $id
  let res = m.movCol.db["$cmd"].makeQuery(%*{
    "aggregate": m.movCol.name,
    "pipeline": [
      {"$match": {"_id": id}},
      {"$limit": 1},
      {
        "$lookup": {
          "from": "categories",
          "localField": "category_ids",
          "foreignField": "_id",
          "as": "categories"
        }
      },
    ],
    "allowDiskUse": true,
    "cursor": {"batchSize": 1},
  }).limit(1).first.toStatusReply
  if not res.ok:
    echo res.err
    raiseFatalError("Opps! something unexpected happened")
  let data = res.bson["cursor"]["firstBatch"].to seq[AggregateMovie]
  if data.len != 1: raiseNotFoundError("movie not found")
  result = data[0]

proc getMovies*(m: MovieService, ctx: ContextLogger, page, limit: int32; categories: seq[Oid] = @[]) : AggregateMoviesAndCount =
  mixin info
  var filter = %*{}
  if categories.len > 0:
    filter["category_ids"] = %*{"$in": categories}
  let res = m.movCol.db["$cmd"].makeQuery(%*{
    "aggregate": m.movCol.name,
    "pipeline": [
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

proc deleteMovie*(m: MovieService, ctx: ContextLogger, id: Oid) : AggregateMovie =
  mixin info
  ctx.info "UserService::deleteUser", "MovieID", $id
  result = m.getMovie(ctx, id)
  m.movCol.remove(%*{"_id": id}, 1).parseRemove(Movie, true)
  discard m.wlCol.update(%*{"movie_ids": id}, %*{"$pull": {"movie_ids": id}}, true, false) # do nothing if command fails

proc updateMovie*(m: MovieService, ctx: ContextLogger, id: Oid, update: UpdateMovieRequest) : Movie =
  mixin info
  ctx.info "MovieService::updateMovie", "MovieID", $id, "Update", update
  result = m.movCol.findAndModify(%*{"_id": id}, nil, %*{"$set": update}, true, false).parseFindAndModify(Movie)
