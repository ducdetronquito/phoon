import asynchttpserver


type
    Response* = object
        status_code*: HttpCode
        body*: string


proc NotFound*(body: string): Response =
    var response = Response(status_code: Http404, body: body)
    return response


proc MethodNotAllowed*(body: string): Response =
    var response = Response(status_code: Http405, body: body)
    return response


proc Ok*(body: string): Response =
    var response = Response(status_code: Http200, body: body)
    return response


proc Created*(body: string): Response =
    var response = Response(status_code: Http201, body: body)
    return response