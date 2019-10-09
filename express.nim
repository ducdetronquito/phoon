from asynchttpserver import Http404, Http405, HttpMethod, newAsyncHttpServer, respond, Request, serve
import asyncdispatch
from options import get, isNone, isSome, none, Option
from routing import dispatch, match_method, Route


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


proc get_route(app: App, request: Request): Option[Route] =
    var potential_route: Option[Route]
    for route in app.routes:
        potential_route = route.dispatch(request)
        if potential_route.isSome:
            return potential_route

    return none(Route)

proc dispatch(app: App, request: Request): Future[void] =
    let potential_route = app.get_route(request)
    if potential_route.isNone:
        return request.respond(Http404, "")

    let route: Route = potential_route.get()
    if route.match_method(request):
        return route.callback(request)
    else:
        return request.respond(Http405, "")


proc serve*(app: App) =
    let server = newAsyncHttpServer()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        await app.dispatch(request)

    waitFor server.serve(Port(8080), main_dispatch)
