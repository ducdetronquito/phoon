from asynchttpserver import nil


type
    Request* = ref object
        request: asynchttpserver.Request
        headers*: asynchttpserver.HttpHeaders


proc new*(response_type: type[Request], std_request: asynchttpserver.Request, headers: asynchttpserver.HttpHeaders): Request =
    return Request(request: std_request, headers: headers)


proc path*(self: Request): string =
    return self.request.url.path


proc http_method*(self: Request): asynchttpserver.HttpMethod =
    return self.request.reqMethod
