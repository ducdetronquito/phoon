import asynchttpserver


type
    Response* = object
        status_code*: HttpCode
        body*: string


proc Ok*(body: string = ""): Response =
    return Response(status_code: Http200, body: body)


proc Created*(body: string = ""): Response =
    return Response(status_code: Http201, body: body)


proc NoContent*(body: string = ""): Response =
    return Response(status_code: Http204, body: body)


proc Unauthenticated*(body: string = ""): Response =
    return Response(status_code: Http401, body: body)


proc NotFound*(body: string = ""): Response =
    return Response(status_code: Http404, body: body)


proc MethodNotAllowed*(body: string = ""): Response =
    return Response(status_code: Http405, body: body)


proc Teapot*(body: string = ""): Response =
    return Response(status_code: Http418, body: body)


proc BadRequest*(body: string = ""): Response =
    return Response(status_code: Http500, body: body)
