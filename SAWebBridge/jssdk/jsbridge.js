var JSBridge = function() {}
JSBridge.prototype.init = function(params) {
  window.webkit.messageHandlers.initSDK.postMessage(params || '')
}
JSBridge.prototype.send = function(json) {
  return window.prompt(`{"type": "bridge", "body": ${json}}`)
}
window.jsbridge = new JSBridge()
