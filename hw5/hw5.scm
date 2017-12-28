(define listdiff? (lambda (x) 
    (and (pair? x) 
        (letrec ([do (lambda (x y) 
                (cond
                    [(eq? x y) #t]
                    [(not (pair? x)) #f]
                    [else (do (cdr x) y)]))])
            (do (car x) (cdr x))))))

(define not-ld? (lambda (x)
    (not (listdiff? x))))

(define null-ld? (lambda (x)
    (and (listdiff? x) (eq? (car x) (cdr x)))))

(define cons-ld (lambda (obj x)
    (if (not-ld? x)
        "error"
        (cons (cons obj (car x)) (cdr x)))))

(define car-ld (lambda (x)
    (if (or (not-ld? x) (null-ld? x)) 
        "error"
        (caar x))))

(define cdr-ld (lambda (x)
    (if (or (not-ld? x) (null-ld? x)) 
        "error"
        (cons (cdar x) (cdr x)))))

(define listdiff (lambda (first . rest)
    (cons (cons first rest) '())))

(define length-ld (lambda (x)
    (if (not-ld? x)
        "error"
        (letrec ([do (lambda (x y)
                    (if (eq? x y) 0 (+ 1 (do (cdr x) y))))])
            (do (car x) (cdr x))))))

(define append-ld (lambda (first . rest)
    (if (not-ld? first)
        "error"
        (if (empty? rest)
            first
            (apply append-ld (cons (append (listdiff->list first) (caar rest)) (cdar rest)) (cdr rest))))))         

(define list-tail-ld (lambda (x k)
    (if (not-ld? x)
        "error"
        (cond
            [(= k 0) x]
            [(or (< k 0) (> k (length-ld x))) "error"]
            [else (list-tail-ld (cdr-ld x) (- k 1))]))))

(define list->listdiff (lambda (x)
    (if (not (list? x))
        "error"
        (apply listdiff (car x) (cdr x)))))

(define listdiff->list (lambda (x)
    (let ([xlength (length-ld x)])
        (if (not (number? xlength)) 
            "error"
            (take (car x) xlength)))))          

; helper for expr-returning makes expr creating the listdiff car
(define make-car-ld (lambda (x)
    (unless (empty? x)
        `(cons ',(car x) ,
            (if (= (length x) 1)
                'tail ; listdiff cdr will be named "tail" in expr-returning
                (make-car-ld (cdr x)))))))

(define expr-returning (lambda (x)
    (if (not-ld? x)
        "error"
        (let ([ld (listdiff->list x)] [tail (cdr x)])
            `(let ([tail ',tail]) (cons ,(if (empty? ld) 
                                            'tail ; in case listdiff x is null then cons tail with tail
                                            (make-car-ld ld)) tail))))))          