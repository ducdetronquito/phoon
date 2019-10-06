from asynchttpserver import Http404, HttpMethod, newAsyncHttpServer, respond, Request, serve
import asyncdispatch
from options import isSome, get
from routing import dispatch, Route


type
    App* = object
        route: Route

proc get*(app: var App, path: string, callback: proc (request: Request): Future[system.void]) =
    app.route = Route(
        callback: callback,
        http_method: HttpMethod.HttpGet
    )


proc dispatch(app: App, request: Request): Future[void] =
    var action = app.route.dispatch(request)
    if action.isSome:
        return action.get()(request)
    else:
        return request.respond(Http404, "")


proc serve*(app: App) =
    let server = newAsyncHttpServer()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        await app.dispatch(request)

    waitFor server.serve(Port(8080), main_dispatch)
