var SDKProtocol = {
  jssdk: "jssdk",
  localStorageSet: "localStorage.setItem",
  localStorageGet: "localStorage.getItem",
  localStorageRemove: "localStorage.removeItem",
  localStorageClear: "localStorage.clear",
  register: "jssdk_register",
  unregister: "jssdk_unregister",
  resolve: "jssdk_exec_resolve",
  reject: "jssdk_exec_reject"
}

var SDKError = {
  unknown: "ERR_UNKNOWN_JSBRIDGE"
}

var SDKMessageType = {
  progress: "progress",
  promise: "promise",
  promise_result: "promise_result",
  normal: "normal"
}

function Jssdk() {
  this._sessionId = 0
  this._callbacks = {}
  this._registers = {}
}

// MARK: Public functions

Jssdk.prototype.exec = function (action, params, progress) {
  // console.log(`jssdk.exec() - action: ${action}`)
  let sessionId = this._newSession(progress)
  let result = this._send(sessionId, SDKProtocol.jssdk + '.' + action, params)
  return this._handleJsBridgeResult(result, sessionId)
}

Jssdk.prototype.register = function (action, callback) {
  // console.log(`jssdk.register() - action: ${action}`)
  if (!action || typeof action !== 'string') return
  if (typeof callback !== 'function') return

  if (!Array.isArray(this._registers[action])) {
    this._registers[action] = []
  }
  if (this._registers[action].includes(callback)) return
  
  this._registers[action].push(callback)
  
  this._send(this._newSession(),  SDKProtocol.register + '.' + action)
}

Jssdk.prototype.unregister = function (action, callback) {
  // console.log(`jssdk.unregister() - action: ${action}`)
  if (!action || typeof action !== 'string') return
  if (typeof callback !== 'function') return
  if (!Array.isArray(this._registers[action])) return

  let index = this._registers[action].indexOf(callback)
  if (index < 0) return
  this._registers[action].splice(index, 1)
  if (this._registers[action].length == 0) {
    this._send(this._newSession(), SDKProtocol.unregister + '.' + action)
  }
}

Jssdk.prototype.resolve = function (id, data) {
  // console.log(`jssdk.resolve() - id: ${id}`)
  this._send(id, SDKProtocol.resolve, data)
}

Jssdk.prototype.reject = function (id, code, msg) {
  // console.log(`jssdk.resolve() - id: ${id}`)
  this._send(id, SDKProtocol.reject, { code, msg })
}

// MARK: Private functions

Jssdk.prototype._hookLocalStorage = function() {
  window.localStorage.setItem = (key, value) => {
    this.exec(SDKProtocol.localStorageSet, {key: String(key), value: JSON.stringify(value)})
  }
  window.localStorage.getItem = (key) => {
    try {
      return JSON.parse(this.exec(SDKProtocol.localStorageGet, {key: String(key)}))
    } catch (e) {
      return undefined
    }
  }
  window.localStorage.removeItem = (key) => {
    this.exec(SDKProtocol.localStorageRemove, {key: String(key)})
  }
  window.localStorage.clear = () => {
    this.exec(SDKProtocol.localStorageClear)
  }
}

Jssdk.prototype._newSession = function(progress) {
  this._sessionId++
  if (this._sessionId > 10000) {
    this._sessionId = 1
  }
  let callback = {}
  if (typeof progress === 'function') {
    callback.progress = progress
  }
  callback.promise = new Promise((resolve, reject) => {
    callback.resolve = resolve
    callback.reject = reject
  })
  this._callbacks[this._sessionId] = callback
  return this._sessionId
}

Jssdk.prototype._delSession = function(sessionId) {
  delete this._callbacks[sessionId]
}

Jssdk.prototype._makeErrorResult = function(code) {
  return {
    code: code
  }
}

Jssdk.prototype._send = function(sessionId, action, params) {
  let obj = { sessionId, action, params }
  return window.jsbridge.send(JSON.stringify(obj))
}

Jssdk.prototype._onReceive = function(message) {
  // console.log(`_onReceive ${message}`)
  if (message && typeof message === 'string') message = JSON.parse(message)
  if (!message || typeof message !== 'object') {
    return this._makeErrorResult(SDKError.unknow)
  }

  if (message.type === 'exec') {
    this._handleExec(message)
  } else {
    this._handleJsBridgeResult(message)
  }
}

Jssdk.prototype._handleMessage = function(message, sessionId) {
  if (message && typeof message === 'string') message = JSON.parse(message)
  if (!message || typeof message !== 'object') {
    throw new Error(SDKError.unknow)
  }
  if (sessionId) message.sessionId = sessionId
  if (typeof message.sessionId !== 'number' || typeof message.type !== 'string') {
    throw new Error(SDKError.unknow)
  }
  return message
}

Jssdk.prototype._handleJsBridgeResult = function(message, sessionId) {
  // console.log(`jssdk._handleJsBridgeResult() - result: ${JSON.stringify(message)}`)
  try {
    message = this._handleMessage(message, sessionId)
  } catch (e) {
    return this._makeErrorResult(e.name)
  }
  let callback = this._callbacks[message.sessionId]
  if (!callback) {
    return this._makeErrorResult(SDKError.unknow)
  }

  sessionId = message.sessionId
  let type = message.type
  delete message.sessionId
  delete message.type
  switch (type) {
    case SDKMessageType.progress: // 进度回调
      // console.log('Type progress: ', JSON.stringify(message))
      if (typeof callback.progress === 'function') {
        callback.progress(message)
      }
      break
    case SDKMessageType.promise_result: // promise结果回调
      // console.log('Type promise_result')
      if (message.code === 'SUCCESS') {
        callback.resolve(message.data)
      } else {
        callback.reject(message)
      }
      this._delSession(sessionId)
      break
    case SDKMessageType.promise: // 返回promise对象
      // console.log('Type promise')
      return callback.promise
    case SDKMessageType.normal: // 同步返回结果
    default:
      // console.log('Type normal')
      this._delSession(sessionId)
      if (message.code === 'SUCCESS') {
        return message.data
      }
      return message
  }
}

Jssdk.prototype._handleExec = function (message) {
  // console.log(`jssdk._handleExec() - message: ${message}`)
  try {
    message = this._handleMessage(message)
  } catch (e) {
    return this._makeErrorResult(e.name)
  }
  let action = message.action
  if (action && typeof action === 'string') {
    let callbacks = this._registers[action]
    if (Array.isArray(callbacks)) {
      for (let i = callbacks.length - 1; i >= 0; i--) {
        try {
          if (callbacks[i](message.sessionId, message.data, message.from) === true) break
        } catch (e) {
          // console.log('Jssdk _handleExec err:' + e)
        }
      }
    }
  }
}
