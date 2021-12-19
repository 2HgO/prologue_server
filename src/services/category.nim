import mongo
import mongo/clientbase
import oids
import times

import ../models/category
import ../utils/[mongoutils]
import ../errors/exceptions
import ../routes/interfaces

type
  CategoryService* = ref object
    catCol*: Collection[Mongo]
    usrCol: Collection[Mongo]
    movCol: Collection[Mongo]

proc newCategoryService*(db: Database[Mongo]) : CategoryService {.inline.} = CategoryService(catCol: db["categories"], usrCol: db["users"], movCol: db["movies"])

proc createCategory*(c: CategoryService, ctx: ContextLogger, category: var Category) =
  mixin info
  category.created_at = now()
  category.updated_at = category.created_at
  let res = c.catCol.insert(%*category)
  if res.inserted_ids.len == 0:
    echo res.err
    raiseFatalError("an error occured")
  category.id = res.inserted_ids[0].to(Oid)

proc getCategory*(c: CategoryService, ctx: ContextLogger, id: Oid) : Category =
  mixin info
  ctx.info "UserService::getCategory", "CategoryID", $id
  let res = c.catCol.find(%*{"_id": id}).limit(1)
  for i in res.items:
    return i.to(Category)
  raiseNotFoundError("category not found")

proc getCategories*(c: CategoryService, ctx: ContextLogger, page, limit: int32) : CategoriesAndCount =
  mixin info
  let res = c.catCol.find(%*{}).skip((page - 1) * limit).limit(limit)
  var catList: seq[Category] = @[]
  let count = res.len
  for i in res.items:
    catList.add i.to(Category)
  # let count = c.catCol.len
  result = CategoriesAndCount(categories: catList, count: count.uint64)

proc deleteCategory*(c: CategoryService, ctx: ContextLogger, id: Oid) : Category =
  mixin info
  ctx.info "UserService::deleteUser", "CategoryID", $id
  result = c.getCategory(ctx, id)
  c.catCol.remove(%*{"_id": id}, 1).parseRemove(Category, true)
  discard c.movCol.update(%*{"category_ids": id}, %*{"$pull": {"category_ids": id}}, true, false) # do nothing is comman fails
  discard c.usrCol.update(%*{"like_ids": id}, %*{"$pull": {"like_ids": id}}, true, false) # do nothing is comman fails

proc updateCategory*(c: CategoryService, ctx: ContextLogger, id: Oid, update: UpdateCategoryRequest) : Category =
  mixin info
  ctx.info "CategoryService::updateCategory", "CategoryID", $id, "Update", update
  result = c.catCol.findAndModify(%*{"_id": id}, nil, %*{"$set": update}, true, false).parseFindAndModify(Category)
