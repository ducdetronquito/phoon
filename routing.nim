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


proc match(route: Route, request: Request): bool =
    return route.path == request.url.path


proc match_method*(route: Route, request: Request): bool =
    return route.http_method == request.reqMethod


proc dispatch*(route: Route, request: Request): Option[Route] =
    if not route.match(request):
        return none(Route)

    return some(route)
