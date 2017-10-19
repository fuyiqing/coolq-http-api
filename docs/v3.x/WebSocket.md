# WebSocket

除了 HTTP 方式调用 API、接收事件上报，目前插件还支持 WebSocket。使用 WebSocket 时，只需要你的机器人程序单方面的向插件建立连接，即可调用 API 和接收事件推送。数据全部使用 JSON 格式传递。

要使用 WebSocket，首先需要在配置文件中填写如下配置：

```ini
ws_host=0.0.0.0  # 监听的 IP
ws_host=6700  # 监听的端口
use_ws=yes  # 使用启用 WebSocket
```

重启插件后，便启动了 WebSocket 服务器（如果你不再需要 HTTP 接口，可以设置 `use_http=no`，注意这不会影响 `post_url` 的作用）。

插件提供了两个接口 `/api/` 和 `/event/`，分别用于调用 API 和推送事件。

如果配置文件中填写了 `access_token`，则建立连接时需要在请求头中加入验证头：

```http
Authorization: Token kSLuTF2GC2Q4q4ugm3
```

或者在 URI 中指定，如 `/api/?access_token=kSLuTF2GC2Q4q4ugm3`。

## `/api/`

连接此接口后，向插件发送如下结构的 JSON 对象，即可调用相应的 API：

```json
{
    "action": "send_private_msg",
    "params": {
        "user_id": 123456,
        "message": "你好"
    }
}
```

这里的 `action` 参数用于指定要调用的 API，具体支持的 API 可以参考 [API 列表](#/API?id=api-%E5%88%97%E8%A1%A8)。`params` 用于传入参数，如果要调用的 API 不需要参数，则可以不加。

客户端向插件发送 JSON 之后，插件会往回发送一个调用结果，结构和 [响应说明](#/API?id=%E5%93%8D%E5%BA%94%E8%AF%B4%E6%98%8E) 是一样的，唯一的区别在于，调用 HTTP 接口时，通过 HTTP 状态码反应的错误情况，被移动到响应 JSON 的 `retcode` 字段，例如，HTTP 接口返回 404 的情况，对应到 WebSocket 的回复，是：

```json
{
    "status": "failed",
    "retcode": 1404
    "data": null
}
```

下面是 `retcode` 和 HTTP 接口的状态码的对照：

| `retcode` | HTTP 接口中的状态码 |
| --------- | ----------------- |
| 1400 | 400 |
| 1401 | 401 |
| 1403 | 403 |
| 1404 | 404 |

目前实际上 `1401` 和 `1403` 并不会真的返回，因为如果建立连接时鉴权失败，连接会直接断开，根本不可能进行到后面的接口调用阶段。

对于 `/api/` 接口，你可以保持连接，也可以每次请求是重新建立连接，区别不是很大。

## `/event/`

连接此接口后，插件会在收到事件后推送至客户端，推送的格式和 HTTP POST 方式上报的完全一致，见 [上报数据格式](#/Post?id=%E4%B8%8A%E6%8A%A5%E6%95%B0%E6%8D%AE%E6%A0%BC%E5%BC%8F)，事件列表见 [事件列表](#/Post?id=%E4%BA%8B%E4%BB%B6%E5%88%97%E8%A1%A8)。

与 HTTP 上报不同的是，WebSocket 推送不会对数据进行签名（即 HTTP 上报中的 `X-Signature` 请求头在这里没有等价的东西），并且也不会处理响应数据。如果对事件进行处理的时候需要调用接口，请使用 HTTP 接口或 WebSocket 的 `/api/` 接口。

此外，这个接口和配置文件的 `post_url` 不冲突，如果开启了 WebSocket 支持，同时 `post_url` 也不为空的话，插件会先通过 HTTP 上报给 `post_url`，在处理完它的响应后，向所有已连接了 `/event/` 的 WebSocket 客户端推送事件。