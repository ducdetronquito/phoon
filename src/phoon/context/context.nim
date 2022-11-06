from asynchttpserver import nil
import request
import response
import ../routing/tree


type
    Context* = ref object
        request*: request.Request
        parameters*: Parameters
        response*: Response


proc new*(contextType: type[Context], request: asynchttpserver.Request): Context =
    return Context(
        request: Request.new(request = request, headers = request.headers),
        response: Response.new()
    )
