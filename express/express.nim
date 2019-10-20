from asynchttpserver import HttpCode, Http404, Http405, HttpMethod, newAsyncHttpServer, respond, Request, serve
import asyncdispatch
from options import get, isNone, isSome, none, Option, some
import routing/route
import routing/router
import response

type
    App* = object
        router: Router


proc get*(app: var App, path: string, callback: proc (request: Request): Response) =
    app.router.add_get_endpoint(path, callback)


proc post*(app: var App, path: string, callback: proc (request: Request): Response) =
    app.router.add_post_endpoint(path, callback)


proc dispatch*(app: App, request: Request): Response =
    let path = request.url.path
    let potential_route = app.router.get_route(path)
    if potential_route.isNone:
        return NotFound("")

    let route = potential_route.get()
    let callback = route.get_callback_of(request.reqMethod)

    if callback.isNone:
        return MethodNotAllowed("")
    
    {.gcsafe.}:
        return callback.get()(request)


proc serve*(app: App) =
    let server = newAsyncHttpServer()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        let response = app.dispatch(request)
        await request.respond(response.status_code, response.body)

    waitFor server.serve(Port(8080), main_dispatch)
