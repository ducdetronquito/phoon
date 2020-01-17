import asynchttpserver
import routing/tree


type
    Response* = ref object
        status_code*: HttpCode
        body*: string
        headers*: HttpHeaders


proc new (response_type: type[Response]): Response =
    return Response(status_code: Http200, body: "", headers: newHttpHeaders())


type
    Context* = ref object
        request*: Request
        parameters*: Parameters
        response*: Response


proc from_request*(context_type: type[Context], request: Request): Context =
    return Context(request: request, response: Response.new())
