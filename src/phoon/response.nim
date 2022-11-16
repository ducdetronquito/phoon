import asynchttpserver


type
    Response* = ref object
        status: HttpCode
        body: string
        headers: HttpHeaders


proc getBody*(self: Response): string =
    return self.body


proc getStatus*(self: Response): HttpCode =
    return self.status


proc getHeaders*(self: Response): HttpHeaders =
    return self.headers


proc new*(responseType: type[Response]): Response =
    return Response(status: Http200, body: "", headers: newHttpHeaders())


proc body*(self: Response, body: string): Response {.discardable.} =
    self.body = body
    return self


proc status*(self: Response, status: HttpCode): Response {.discardable.} =
    self.status = status
    return self


proc headers*(self: Response, key: string, value: string): Response {.discardable.} =
    self.headers.add(key, value)
    return self


proc cookie*(self: Response, name: string, value: string): Response {.discardable.} =
    self.headers.add("Set-Cookie", name & "=" & value)
    return self
