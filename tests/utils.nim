import asynchttpserver
import uri


proc Request*(http_method: HttpMethod, path: string): Request =
    let uri = parseUri(path)
    return Request(reqMethod: http_method, url: uri)

proc GetRequest*(path: string): Request =
    let uri = parseUri(path)
    return Request(HttpMethod.HttpGet, path)

proc PostRequest*(path: string): Request =
    return Request(HttpMethod.HttpPost, path)
