from asynchttpserver import nil
import config, request, response, tree


type
    Context* = ref object
        request*: Request
        parameters*: Parameters
        response*: Response
        config*: Config


proc new*(contextType: type[Context], request: asynchttpserver.Request, config: Config): Context =
    return Context(
        request: Request.new(request = request, headers = request.headers),
        response: Response.new(),
        config: config
    )
