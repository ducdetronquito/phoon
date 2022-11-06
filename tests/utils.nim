import asynchttpserver
import uri


proc Request*(httpMethod: HttpMethod, path: string): Request =
    let uri = parseUri(path)
    return Request(reqMethod: httpMethod, url: uri)

proc GetRequest*(path: string): Request =
    let uri = parseUri(path)
    return Request(HttpMethod.HttpGet, path)

proc PostRequest*(path: string): Request =
    return Request(HttpMethod.HttpPost, path)
