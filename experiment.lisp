(defpackage :gl-ui
  (:use :common-lisp))
(in-package :gl-ui)

;;; FIXME: What sort of installation requirements does this involve?
(ql:quickload 'lispbuilder-sdl)
;;; At the very least, this requires sdl-image
(ql:quickload 'lispbuilder-sdl-image)
(ql:quickload 'cl-opengl)

;;; Code brazenly stolen from 
;;; http://3bb.cc/tutorials/cl-opengl/getting-started.html
(defmacro restartable (&body body)
  "helper macro since we use continue restarts a lot
--remember to hit C in slime or pick the restart so errors don't kill the app"
  `(restart-case
       (progn ,@body)
     (continue () :report "Continue")))

(defun draw ()
  "draw a frame"
  (gl:clear :color-buffer-bit)
  ;; draw a triangle
  (gl:with-primitive :triangles
    (gl:color 1 0 0)
    (gl:vertex 0 0 0)
    (gl:color 0 1 0)
    (gl:vertex 0.5 1 0)
    (gl:color 0 0 1)
    (gl:vertex 1 0 0))

  ;; finish the frame
  (gl:flush)
  (sdl:update-display))

(defun main-loop ()
  (sdl:with-init ()
    (sdl:window 320 240 :flags sdl:sdl-opengl)
    (setf (sdl:frame-rate) 60)

    ;; cl-opengl needs platform specifec support to be able to load GL
    ;; extensions, so we need to tell it how to do so in silpbuilder-sdl
    (setf cl-opengl-bindings:*gl-get-proc-address* #'sdl-cffi::sdl-gl-get-proc-address)
    (sdl:with-events (:poll)
      (:quit-event () t)
      (:key-down-event (:key key)
		       (when (sdl:key= key :sdl-key-escape)
			 (sdl:push-quit-event)))
      (:video-expose-event ()
			   (sdl:update-display))
      (:idle ()
	     ;; this lets slime keep working while the main loop is
	     ;; running in sbcl using the :fd-handler 
	     ;; swank:*communication-style*
	     ;; (something similar might help in some other lisps, not
	     ;; sure which though)

	     ;; Actually, this seems to have been jacked from CMUCL
	     ;; That has documentation for it. SBCL seems to have swept
	     ;; it under the rug
	     #+(and sbcl (not sb-thread)) (restartable
					    (sb-sys:serve-all-events 0))

	     ;; Q: So, what's the CCL equivalent?
	     ;; A: Seems to be kicking off main loop in its own thread
	     ;#+ccl (error "What do I do?"))

	     #-(or ccl
		   (and sbcl (not sb-thread)))
	     (error "Unknown system")
	     
	     (restartable (draw))))))

#+sbcl (main-loop)
#+ccl (ccl:process-run-function "window" #'main-loop)
#- (or ccl
       (and sbcl (not-sb-thread)))
(error "Unknown system")



