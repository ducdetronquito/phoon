from asynchttpserver import Http404, HttpMethod, newAsyncHttpServer, respond, Request, serve
import asyncdispatch
from options import isSome, get
from routing import dispatch, Route


type
    App* = object
        routes: seq[Route]

proc get*(app: var App, path: string, callback: proc (request: Request): Future[system.void]) =
    app.routes.add(
        Route(
            path: path,
            callback: callback,
            http_method: HttpMethod.HttpGet
        )
    )


proc dispatch(app: App, request: Request): Future[void] =
    for route in app.routes:
        let action = route.dispatch(request)
        if action.isSome:
            return action.get()(request)

    return request.respond(Http404, "")


proc serve*(app: App) =
    let server = newAsyncHttpServer()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        await app.dispatch(request)

    waitFor server.serve(Port(8080), main_dispatch)
