;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This example shows how to define your own polyphonic synths
;;
;; You will first need to load and compile dsp_library.scm
;;
;; Then you're OK to go
;;
;; NOTE [at the moment compiling in a secondary thread is a little
;;      [flakey.  I'm working on this so in the mean time you'll
;;      [just have to put up with the audio delays while compiling
;;


;; first let's play with the default synth defined in dsp_library
;; the default synth is called .... synth
(define loop
  (lambda (beat offset dur)
    (play-note (*metro* beat) synth (+ offset (random '(60 62 63 65 67))) 80 2000)
    (callback (*metro* (+ beat (* dur .5))) 'loop
	      (+ beat dur)
	      offset
	      dur)))


(loop (*metro* 'get-beat 4) 0 1/2) ;; start one playing quavers
(loop (*metro* 'get-beat 4) 12 1/3) ;; another playing triplets

;; to create our own instrument
;; we first need to compile a kernel function
;; this is the dsp code that gets rendered for each note
;; it must be a closure that returns a closure
;; 
;; lets try a simple sawwave synth
(definec my-saw-synth
  (lambda ()
    (let ((sawl (make-saw))
	  (sawr (make-saw)))
      (lambda (time:double chan:double freq:double amp:double)
	(cond ((< chan 1.0)
	       (sawl amp freq))
	      ((< chan 2.0)
	       (sawr amp freq))
	      (else 0.0)))))))

;; now define an instrument to use my-additive-synth note kernel
;; with a default (i.e. pass through) default-effect
(define-instrument my-synth my-saw-synth default-effect)
    

;; finally we need to add the new synth to the dsp routine
;; this is only slightly modified from the on in dsp_library
;; we just sum my-synth with synth and add some delay
;;
;; NOTE: then 100000 is extra memory for our
;; comb filters
(definec dsp 1000000
  (let ((combl (make-comb (dtoi64 (* 0.25 *samplerate*))))
	(combr (make-comb (dtoi64 (* 0.33333333 *samplerate*)))))
    (lambda (in:double time:double chan:double dat:double*)
      (cond ((< chan 1.0)
	     (combl (+ (* 1.0 (synth in time chan dat))
		       (my-synth in time chan dat))))
	    ((< chan 2.0)	     
	     (combr (+ (* 1.0 (synth in time chan dat))
		       (my-synth in time chan dat))))
	    (else 0.0)))))

;;make my-synth active
(my-synth.active 1)

;; now start a temporal recursion to play the new synth
(define loop2
  (lambda (beat dur)
    (let ((pitch (random '(55 36 63 70 72))))
      (play-note (*metro* beat) my-synth pitch 
      		 (if (= pitch 36) 105 95) 3000)
      (callback (*metro* (+ beat (* dur .5))) 'loop2
		(+ beat dur)
		dur))))

(loop2 (*metro* 'get-beat 4) 1/3) ;; play our new synth


;; we can recompile my-saw-synth into something 
;; else whenever we like
;; here's something more complex
(definec my-saw-synth
  (let ((res 15.0)
	(cof 8000.0))
    (lambda ()
      (let ((sawl (make-saw))
	    (sawl2 (make-saw))
	    (modl (make-oscil 0.0))
	    (lpfl (make-lpf))
	    (lpflmod (make-oscil 0.0))
	    (sawr (make-saw))
	    (sawr2 (make-saw))
	    (modr (make-oscil 0.0))
	    (lpfr (make-lpf))
	    (lpfrmod (make-oscil 0.0)))
	(lpfl.res res)
	(lpfr.res res)
	(lambda (time:double chan:double freq:double amp:double)
	  (cond ((< chan 1.0)
		 (lpfl (* amp (+ (sawl (* 1.0 amp) freq) 
				 (sawl2 amp (+ freq (modl 10.0 0.2)))))
		       (+ cof (lpflmod freq 1.0))))
		((< chan 2.0)			     		  
		 (lpfr (* amp (+ (sawr (* 1.0 amp) freq) 
				 (sawr2 amp (+ freq (modr 50.0 0.5)))))
		       (+ cof (lpfrmod 1400.0 2.0))))
		(else 0.0)))))))


;; some event level modification to my-synth
;; adjust res cof of my-additive-synth (dsp kernel)
;; adjust release of my-synth (instrument)
(define res-sweep
  (lambda (beat dur)
    (my-synth.release (cosr 12000.0 11000.0 1/29)) 
    (my-saw-synth.res (cosr 40.0 30.0 1/37))
    (my-saw-synth.cof (cosr 5000.0 3500.0 1/19))
    (callback (*metro* (+ beat (* dur .5))) 'res-sweep
	      (+ beat dur) dur)))

(res-sweep (*metro* 'get-beat 4.0) 1/8)