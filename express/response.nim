from asynchttpserver import HttpCode, Http200, Http201, Http404, Http405


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


# TODO: Rename the method `Ok` when the next version of Nim is out.
# Cf: https://github.com/nim-lang/Nim/issues/12465
proc Ok200*(body: string): Response =
    var response = Response(status_code: Http200, body: body)
    return response


proc Created*(body: string): Response =
    var response = Response(status_code: Http201, body: body)
    return response