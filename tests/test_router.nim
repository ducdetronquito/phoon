import phoon
import phoon/route
import unittest


suite "Router":

    test "Can chain http method":
        let router = Router()
        var route = router.route("/a-route/")
            .delete(
                proc (ctx: Context) {.async.} =
                    discard
            )
            .get(
                proc (ctx: Context) {.async.} =
                    discard
            )
            .head(
                proc (ctx: Context) {.async.} =
                    discard
            )
            .options(
                proc (ctx: Context) {.async.} =
                    discard
            )
            .patch(
                proc (ctx: Context) {.async.} =
                    discard
            )
            .post(
                proc (ctx: Context) {.async.} =
                    discard
            )
            .put(
                proc (ctx: Context) {.async.} =
                    discard
            )

        check(route.onDelete.isSome)
        check(route.onGet.isSome)
        check(route.onHead.isSome)
        check(route.onOptions.isSome)
        check(route.onPatch.isSome)
        check(route.onPost.isSome)
        check(route.onPut.isSome)
