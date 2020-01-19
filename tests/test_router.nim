import phoon
import phoon/routing/route
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

        check(route.delete_callback.isSome)
        check(route.get_callback.isSome)
        check(route.head_callback.isSome)
        check(route.options_callback.isSome)
        check(route.patch_callback.isSome)
        check(route.post_callback.isSome)
        check(route.put_callback.isSome)
