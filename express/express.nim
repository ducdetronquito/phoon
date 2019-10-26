import asynchttpserver
import asyncdispatch
import options
import routing/route
import routing/router
import response
import tables

type
    App* = object
        router: Router


proc get*(app: var App, path: string, callback: proc (request: Request): Response) =
    app.router.add_get_endpoint(path, callback)


proc post*(app: var App, path: string, callback: proc (request: Request): Response) =
    app.router.add_post_endpoint(path, callback)


proc mount*(self: var App, path: string, router: Router) =
    for sub_path, route in router.get_routes().pairs:
        let new_path = path & sub_path
        if route.get_callback.isSome:
            self.router.add_get_endpoint(new_path, route.get_callback.get())

        if route.post_callback.isSome:
            self.router.add_post_endpoint(new_path, route.post_callback.get())


proc dispatch*(app: App, request: Request): Response =
    return app.router.dispatch(request)


proc serve*(app: App) =
    let server = newAsyncHttpServer()

    proc main_dispatch(request: Request) {.async, gcsafe.} =
        let response = app.dispatch(request)
        await request.respond(response.status_code, response.body)

    waitFor server.serve(Port(8080), main_dispatch)
