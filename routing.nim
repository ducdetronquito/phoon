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


proc dispatch*(route: Route, request: Request): Option[Callback] =
    if request.reqMethod != route.http_method:
        return none(Callback)

    if not route.match(request):
        return none(Callback)

    return some(route.callback)
