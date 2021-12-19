import oids

import ./base

type
  Watchlist* = object of DocBase
    ## only for documentation purposes (to model how documents in the watchlists collection look like)
    user_id*: Oid
    movie_ids*: seq[Oid]