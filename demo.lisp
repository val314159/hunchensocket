(ql:quickload (setf *** '(:hunchentoot :hunchensocket :parenscript :cl-who)))

(defpackage :my-chat #.(append '(:use :cl) ***))
(in-package :my-chat)

(defclass chat-room (websocket-resource)
  ((name :initarg :name :initform (error "Name this room!") :reader name))
  (:default-initargs :client-class 'user))

(defclass chat-room2 (websocket-resource)
  ((name :initarg :name :initform (error "Name this room!") :reader name))
  (:default-initargs :client-class 'user))

(defclass user (websocket-client)
  ((name :initarg :user-agent :reader name :initform (error "Name this user!"))))

(defvar *chat-rooms* (list (make-instance 'chat-room :name "/bongo")
                           (make-instance 'chat-room :name "/fury")
                           (make-instance 'chat-room2 :name "/qwert")))

(defun find-room (request)
  (find (script-name request) *chat-rooms* :test #'string= :key #'name))

(pushnew 'find-room *websocket-dispatch-table*)

(defun broadcast (room message &rest args)
  (loop for peer in (clients room)
        do (send-text-message peer (apply #'format nil message args))))

(defun ps*-from-string (message)
  (format nil "{~a}" (ps* (read-from-string message))))

(defmethod client-connected ((room chat-room) user)
  (broadcast room "~a has joined ~a" (name user) (name room)))

(defmethod client-disconnected ((room chat-room) user)
  (broadcast room "~a has left ~a" (name user) (name room)))

(defmethod text-message-received ((room chat-room) user message)
  (broadcast room "~a says ~a" (name user) message))

(defmethod client-connected ((room chat-room2) user)
  (broadcast room "~a hxsssssssssssssssssssas joined ~a" (name user) (name room))
  (broadcast room "{console.log(\"Hello, world2\")}")
  (broadcast room "{~a}" (ps
			  ((@ console log) "Hello, world3")
			  )))

(defmethod text-message-received ((room chat-room2) user message)
  (broadcast room (if (equal (subseq message 0 1) "(")
		      (ps*-from-string message)
		      message)))

(define-easy-handler (index :uri "/") () "
<script>
(function app(){
    var E = document.createElement('div')
    var restart = () =>	setTimeout(app, 500)
    var origin = `ws${location.origin.substr(4)}`
    var ws = window.ws = new WebSocket(origin + '/qwert')
    ws.onmessage = evt => {
        var data = evt.data
        console.log(`1 >> ${data} <<`)
        if(data.startsWith('{')) eval(data)
        else{
            E.innerHTML = data
            var c = E.removeChild(E.firstChild)
            document.body.appendChild(c)}
        console.log(`9 >> ${data} <<`)}
    ws.onclose = () => {console.log('x << CLOSE >>');restart()}
    })()</script>")

(defun main ()
  (start (make-instance 'websocket-easy-acceptor :port 80))
  (format t "listening...~%")
  (sleep 600))
