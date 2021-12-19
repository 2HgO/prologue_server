import prologue
from strutils import parseInt
import std/with

import ../config/env
import ../db/db
import context
import middlewares
import user as user_route
import category as category_route
import movie as movie_route
import watchlist as watchlist_route

proc startApp*() =
  let sett = newSettings(port=Port(APP_PORT.parseInt), appName="prologue-server", debug=false)
  let app = newApp(sett, @[logHandler, errorHandler, corsHandler, setHeaders])

  app.registerErrorHandler(Http404, handleRoute404)
  app.registerErrorHandler(Http500, handleRoute500)

  let
    authBase = app.newGroup("/v1/auth")
    categoryBase = app.newGroup("/v1/categories", @[validateToken])
    movieBase = app.newGroup("/v1/movies", @[validateToken])
    userBase = app.newGroup("/v1/users", @[validateToken])
    watchlistBase = app.newGroup("/v1/watchlists", @[validateToken])

  with authBase:
    post "/register", user_route.createUser
    post "/login", user_route.login
  
  with categoryBase:
    post "", category_route.createCategory
    get "/list", category_route.getCategories
    get "/{categoryID}", category_route.getCategory
    delete "/{categoryID}", category_route.deleteCategory
    patch "/{categoryID}", category_route.updateCategory
  
  with movieBase:
    post "", movie_route.createMovie
    get "/list", movie_route.getMovies
    get "/{movieID}", movie_route.getMovie
    delete "/{movieID}", movie_route.deleteMovie
    patch "/{movieID}", movie_route.updateMovie

  with userBase:
    get "/list", user_route.getUsers
    get "", user_route.getUser
    patch "", user_route.updateUser
    delete "", user_route.deleteUser
    get "/{userID}/watchlist", watchlist_route.getUserWatchlist
  
  with watchlistBase:
    put "/{movieID}", watchlist_route.addMovieToUserWatchList
    delete "/{movieID}", watchlist_route.removeMovieFromUserWatchList
    get "", watchlist_route.getUserWatchlist

  createIndexes(initDB())

  echo "App starting up at: http://localhost:"&APP_PORT
  app.run(ReqContext)
