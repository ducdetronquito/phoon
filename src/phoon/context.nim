import asynchttpserver
import routing/tree


type
    Response* = object
        status_code*: HttpCode
        body*: string


type
    Context* = ref object
        request*: Request
        parameters*: Parameters
        response*: Response


proc from_request*(context_type: type[Context], request: Request): Context =
    var response = Response(status_code: Http200, body: "")
    return Context(request: request, response: response)
