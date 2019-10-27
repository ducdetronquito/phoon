import asynchttpserver
import asyncdispatch
import routing/router
import response


type
    App* = ref object
        router: Router


proc new*(app_type: type[App]): App =
    var app = system.new(App)
    app.router = Router.new()
    return app


proc get*(app: var App, path: string, callback: proc (request: Request): Response) =
    app.router.add_get_endpoint(path, callback)


proc post*(app: var App, path: string, callback: proc (request: Request): Response) =
    app.router.add_post_endpoint(path, callback)


proc dispatch*(app: App, request: Request): Response =
    return app.router.dispatch(request)


proc serve*(app: App) =
    let server = newAsyncHttpServer()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        let response = app.dispatch(request)
        await request.respond(response.status_code, response.body)

    waitFor server.serve(Port(8080), main_dispatch)
