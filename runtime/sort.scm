;;; "sort.scm" Defines: sorted?, merge, merge!, sort, sort!
;;; Author : Richard A. O'Keefe (based on Prolog code by D.H.D.Warren)
;;;
;;; This code is in the public domain.

;;; Updated: 11 June 1991
;;; Modified for scheme library: Aubrey Jaffer 19 Sept. 1991
;;; Updated: 19 June 1995
;;; (sort, sort!, sorted?): Generalized to strings by jaffer: 2003-09-09
;;; (sort, sort!, sorted?): Generalized to arrays by jaffer: 2003-10-04
;;; Modified by Andrew Sorensen for Impromptu 2006-05-10  

;;; (cl:sorted? sequence less?)
;;; is true when sequence is a list (x0 x1 ... xm) or a vector #(x0 ... xm)
;;; such that for all 1 <= i <= m,
;;;	(not (less? (list-ref list i) (list-ref list (- i 1)))).
;@
(define (cl:sorted? seq less?)
  (cond ((null? seq) #t)
	(else (let loop ((last (car seq)) (next (cdr seq)))
	   (or (null? next)
	       (and (not (less? (car next) last))
		    (loop (car next) (cdr next))))))))

;;; (cl:merge a b less?)
;;; takes two lists a and b such that (sorted? a less?) and (sorted? b less?)
;;; and returns a new list in which the elements of a and b have been stably
;;; interleaved so that (sorted? (merge a b less?) less?).
;;; Note:  this does _not_ accept arrays.  See below.
;@
(define (cl:merge a b less?)
  (cond ((null? a) b)
	((null? b) a)
	(else (let loop ((x (car a)) (a (cdr a)) (y (car b)) (b (cdr b)))
		;; The loop handles the merging of non-empty lists.  It has
		;; been written this way to save testing and car/cdring.
		(if (less? y x)
		    (if (null? b)
			(cons y (cons x a))
			(cons y (loop x a (car b) (cdr b))))
		    ;; x <= y
		    (if (null? a)
			(cons x (cons y b))
			(cons x (loop (car a) (cdr a) y b))))))))

;;; (cl:merge! a b less?)
;;; takes two sorted lists a and b and smashes their cdr fields to form a
;;; single sorted list including the elements of both.
;;; Note:  this does _not_ accept arrays.
;@
(define (cl:merge! a b less?)
  (define (loop r a b)
    (if (less? (car b) (car a))
	(begin (set-cdr! r b)
	  (if (null? (cdr b))
	      (set-cdr! b a)
	      (loop b a (cdr b))))
	;; (car a) <= (car b)
	(begin (set-cdr! r a)
	  (if (null? (cdr a))
	      (set-cdr! a b)
	      (loop a (cdr a) b)))))
  (cond ((null? a) b)
	((null? b) a)
	((less? (car b) (car a))
	 (if (null? (cdr b))
	     (set-cdr! b a)
	     (loop b a (cdr b)))
	 b)
	(else (if (null? (cdr a))
	     (set-cdr! a b)
	     (loop a (cdr a) b))
	 a)))

;;; (cl:sort! sequence less?)
;;; sorts the list, array, or string sequence destructively.  It uses
;;; a version of merge-sort invented, to the best of my knowledge, by
;;; David H. D.  Warren, and first used in the DEC-10 Prolog system.
;;; R. A. O'Keefe adapted it to work destructively in Scheme.
;@
(define (cl:sort! seq less?)
  (define (step n)
    (cond ((> n 2)
	   (let* ((j (quotient n 2))
		  (a (step j))
		  (k (- n j))
		  (b (step k)))
	     (cl:merge! a b less?)))
	  ((= n 2)
	   (let ((x (car seq))
		 (y (cadr seq))
		 (p seq))
	     (set! seq (cddr seq))
	     (cond ((less? y x)
		    (set-car! p y)
		    (set-car! (cdr p) x)))
	     (set-cdr! (cdr p) '())
	     p))
	  ((= n 1)
	   (let ((p seq))
	     (set! seq (cdr seq))
	     (set-cdr! p '())
	     p))
	  (else '())))
   (step (length seq)))

;;; (cl:sort sequence less?)
;;; sorts a array, string, or list non-destructively.  It does this
;;; by sorting a copy of the sequence.  My understanding is that the
;;; Standard says that the result of append is always "newly
;;; allocated" except for sharing structure with "the last argument",
;;; so (append x '()) ought to be a standard way of copying a list x.
;@
(define (cl:sort seq less?)
  (cond ((vector? seq)
	 (list->vector (cl:sort! (vector->list seq) less?)))
	((string? seq)
	 (list->string (cl:sort! (string->list seq) less?)))
	(else (cl:sort! (append seq '()) less?))))
