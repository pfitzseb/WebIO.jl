(function () {
    function tryconnect() {
        var ws = new WebSocket("ws://localhost:"+port);
        ws.onopen = function () {
            WebIO.sendCallback = function (msg) {
                ws.send(JSON.stringify(msg));
            }

            ws.onmessage = function (evt) {
                WebIO.dispatch(JSON.parse(evt.data));
            }

            WebIO.triggerConnected();
        }
        ws.onclose = function (evt) {
            console.log(evt);
        }
    }

    tryconnect();
})();
