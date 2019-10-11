from asynchttpserver import Http404, Http405, HttpMethod, newAsyncHttpServer, respond, Request, serve
import asyncdispatch
from options import get, isNone, isSome, none, Option, some
import routing/route
import routing/router

type
    App* = object
        router: Router


proc get*(app: var App, path: string, callback: proc (request: Request): Future[system.void]) =
    app.router.add_get_endpoint(path, callback)


proc post*(app: var App, path: string, callback: proc (request: Request): Future[system.void]) =
    app.router.add_post_endpoint(path, callback)


proc dispatch(app: App, request: Request): Future[void] =
    let path = request.url.path
    let potential_route = app.router.get_route(path)
    if potential_route.isNone:
        return request.respond(Http404, "")

    let route = potential_route.get()
    let callback = route.get_callback_of(request.reqMethod)

    if callback.isNone:
        return request.respond(Http405, "")

    return callback.get()(request)


proc serve*(app: App) =
    let server = newAsyncHttpServer()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        await app.dispatch(request)

    waitFor server.serve(Port(8080), main_dispatch)
