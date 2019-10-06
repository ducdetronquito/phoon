from asyncdispatch import Future
from asynchttpserver import Request, HttpMethod
from options import none, Option, some


type
    Callback* = proc(request: Request): Future[void]


type
    Route* = object
        callback*: Callback
        http_method*: HttpMethod


proc dispatch*(route: Route, request: Request): Option[Callback] =
    if request.reqMethod == route.http_method:
        return some(route.callback)
    else:
        return none(Callback)
