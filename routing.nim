from asyncdispatch import Future
from asynchttpserver import Request, HttpMethod
from options import none, Option, some


type
    Callback* = proc(request: Request): Future[void]


type
    Route* = object
        path*: string
        callback*: Callback
        http_method*: HttpMethod


proc match_method*(route: Route, request: Request): bool =
    return route.http_method == request.reqMethod


proc match_path*(route: Route, path: string): Option[Route] =
    if route.path == path:
        return some(route)

    return none(Route)
