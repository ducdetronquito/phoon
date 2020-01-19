import asynchttpserver


type
    Response* = ref object
        status_code: HttpCode
        body: string
        headers*: HttpHeaders


proc new*(response_type: type[Response]): Response =
    return Response(status_code: Http200, body: "", headers: newHttpHeaders())


proc body*(self: Response, body: string): Response {.discardable.} =
    self.body = body
    return self


proc get_body*(self: Response): string =
    return self.body


proc get_status*(self: Response): HttpCode =
    return self.status_code


proc status*(self: Response, status: HttpCode): Response {.discardable.} =
    self.status_code = status
    return self
