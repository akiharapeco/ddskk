;;; skk-num.el --- $B?tCMJQ49$N$?$a$N%W%m%0%i%`(B
;; Copyright (C) 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997,
;;               1998, 1999, 2000, 2001
;; Masahiko Sato <masahiko@kuis.kyoto-u.ac.jp>

;; Author: Masahiko Sato <masahiko@kuis.kyoto-u.ac.jp>
;; Maintainer: SKK Development Team <skk@ring.gr.jp>
;; Version: $Id: skk-num.el,v 1.16 2001/05/29 21:56:14 minakaji Exp $
;; Keywords: japanese
;; Last Modified: $Date: 2001/05/29 21:56:14 $

;; This file is part of Daredevil SKK.

;; Daredevil SKK is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either versions 2, or (at your option)
;; any later version.

;; Daredevil SKK is distributed in the hope that it will be useful
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Daredevil SKK, see the file COPYING.  If not, write to the Free
;; Software Foundation Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Commentary:

;;; Code:
(eval-when-compile
  (require 'skk-macs)
  (require 'skk-vars))

;;;###autoload
(defun skk-num-compute-henkan-key (key)
  ;; KEY $B$NCf$NO"B3$9$k?t;z$r8=$o$9J8;zNs$r(B "#" $B$KCV$-49$($?J8;zNs$rJV$9!#(B"12"
  ;; $B$d(B "$B#0#9(B" $B$J$IO"B3$9$k?t;z$r(B 1 $B$D$N(B "#" $B$KCV$-49$($k$3$H$KCm0U!#(B
  ;; $BCV$-49$($??t;z$r(B skk-num-list $B$NCf$K%j%9%H$N7A$GJ]B8$9$k!#(B
  ;; $BNc$($P!"(BKEY $B$,(B "$B$X$$$;$$(B7$BG/(B12$B$,$D(B" $B$G$"$l$P!"(B"$B$X$$$;$$(B#$B$M$s(B#$B$,$D(B"
  ;; $B$HJQ49$7!"(Bskk-num-list $B$K(B ("7" "12") $B$H$$$&%j%9%H$rBeF~$9$k!#(B
  ;; $B<-=q$N8+=P$78l$N8!:w$K;HMQ$9$k!#(B
  (let ((numexp (if skk-num-convert-float
		    "[.0-9]+" "[0-9]+")))
    ;;(setq skk-noconv-henkan-key key)
    (save-match-data
      ;; $B0L<h$j$N(B "," $B$r=|5n$9$k!#(B
      (while (string-match "," key)
	(setq key (concat (substring key 0 (match-beginning 0))
			  (substring key (match-end 0)))))
      ;; $BA43Q?t;z$r(B ascii $B?t;z$KJQ49$9$k!#(B
      (while (string-match "[$B#0(B-$B#9(B]" key)
        (let ((zen-num (match-string 0 key)))
          (setq key (concat (substring key 0 (match-beginning 0))
                            (skk-jisx0208-to-ascii zen-num)
                            (substring key (match-end 0))))))
      ;; ascii $B?t;z$r(B "#" $B$KCV$-49$(!"$=$N?t;z$r(B skk-num-list $B$NCf$KJ]B8!#(B
      (while (string-match numexp key)
        (setq skk-num-list (nconc skk-num-list (list (match-string 0 key)))
              key (concat (substring key 0 (match-beginning 0))
                          "#"
                          (substring key (match-end 0)))))))
  key)

(defun skk-num-convert ()
  ;; skk-henkan-list $B$N(B skk-henkan-count $B$,;X$7$F$$$k8uJd(B ($B?tCMJQ49(B
  ;; $B%-!<$N(B) $B$rJQ49$7!"(Bskk-henkan-list $B$r(B
  ;;   ("#2" ...) -> (("#2" ."$B0l(B") ...)
  ;; $B$N$h$&$KJQ7A$9$k!#(B
  (let ((key (skk-get-current-candidate-1))
	convlist current)
    (if (consp key)
	nil
      (setq convlist (skk-num-convert-1 key))
      (cond ((null convlist) nil)
	    ;; CONV-LIST $B$NA4MWAG$,J8;zNs!#(B
	    ((null (memq t (mapcar 'listp convlist)))
	     (setq current (mapconcat 'identity convlist ""))
	     (if (skk-get-current-candidate-1)
		 ;; ("A" "#2" "C") -> ("A" ("#2" ."$B0l(B") "C")
		 (setcar (nthcdr skk-henkan-count skk-henkan-list)
			 (cons key current))
	       (setq skk-henkan-list
		     (nconc skk-henkan-list (list (cons key current))))))
	    ;; #4
	    (t (let ((l (mapcar (function (lambda (e) (cons key e)))
				(skk-num-flatten-list convlist))))
		 (setq current (cdr (car l)))
		 (if (and (> skk-henkan-count -1)
			  (nth skk-henkan-count skk-henkan-list))
		     (progn
		       (setcar (nthcdr skk-henkan-count skk-henkan-list) (car l))
		       (setq skk-henkan-list (skk-splice-in
					      skk-henkan-list
					      (1+ skk-henkan-count)
					      (cdr l))))
		   (setq skk-henkan-list (nconc skk-henkan-list l))
		   (skk-num-uniq))))))))

(defun skk-num-convert-1 (key)
  ;; KEY $B$r(B skk-num-list $B$K=>$$JQ49$7!"JQ498e$NJ8;zNs$N%Q!<%D$r(B
  ;; $B=g$K$J$i$Y$?%j%9%H$rJV$9!#(B
  ;; KEY ::= `$BJ?@.(B#0$BG/(B', return ::= ("$BJ?@.(B" "13" "$BG/(B")
  (if (or (not key) (consp key))
      nil
    (let ((numexp (if skk-num-convert-float
		      "#[.0-9]+" "#[0-9]+"))
	  (n 0)
	  (workkey key)
	  num convnum string convlist beg)
      (save-match-data
        (while (and (setq num (nth n skk-num-list)) ; $B6qBNE*$J?tCM$rJ];}$7$F$$$k%j%9%H$r;2>H$9$k!#(B
                    (setq beg (string-match numexp workkey)))
	  (setq convnum			; $B?tCMJQ49$5$l$?ItJ,$NJ8;zNs(B
		(skk-num-exp		; $B6qBNE*$J?t;z$rJQ49%?%$%W$K=>$$JQ49$9$k!#(B
		 num
		 (string-to-number (substring workkey (1+ beg) (match-end 0))))
                string (substring workkey 0 beg) ; $B=hM}$5$l$??tCM%-!<$^$G$N(B prefix $BJ8;zNs(B
                workkey (substring workkey (match-end 0)) ; $BL$=hM}$NJ8;zNs(B
                n (1+ n))
	  ;; $BJQ49$5$l$?J8;z$H?tCMJQ49$K4X78$N$J$$L5JQ49$NJ8;z$rJB$Y$?%j%9%H(B
	  (setq convlist (nconc convlist (list string convnum))))
        (delete "" (nconc convlist (list workkey)))))))

(defun skk-num-multiple-convert (&optional count)
  (let ((skk-henkan-count skk-henkan-count)
        (n (or count (length skk-henkan-list))))
    (while (and (> n 0) (nth skk-henkan-count skk-henkan-list))
      (skk-num-convert)
      ;; skk-henkan-count $B$rA`:n$7$J$/$H$b(B skk-num-convert $B$,(B
      ;; $BM-8z$K$J$k$h$&$K$7$?$$!#(B
      (setq skk-henkan-count (1+ skk-henkan-count)
            n (1- n)))))

(defun skk-num-rawnum-exp (string)
  (setq string (skk-num-rawnum-exp-1
                string "[$B#0(B-$B#9(B][$B!;0l6e8^;0;M<7FsH,O;(B]" "#9" 0))
  (setq string (skk-num-rawnum-exp-1
                string "\\(^\\|[^#0-9]\\)\\([0-9]+\\)" "#0" 2))
  (setq string (skk-num-rawnum-exp-1
                string "[$B#0(B-$B#9(B]+" "#1" 0))
  (setq string (skk-num-rawnum-exp-1
                string "\\([$B!;0l6e8^;0;M<7FsH,O;==(B][$B==I4@iK|2/C{5~(B]\\)+" "#3" 0))
  ;; (mapcar 'char-to-string
  ;;         (sort
  ;;          '(?$B0l(B ?$BFs(B ?$B;0(B ?$B;M(B ?$B8^(B ?$BO;(B ?$B<7(B ?$BH,(B ?$B6e(B ?$B!;(B) '<))
  ;;   --> ("$B!;(B" "$B0l(B" "$B6e(B" "$B8^(B" "$B;0(B" "$B;M(B" "$B<7(B" "$BFs(B" "$BH,(B" "$BO;(B")
  ;;
  ;; [$B!;(B-$B6e(B] $B$H$$$&@55,I=8=$,;H$($J$$$N$G!"@8$N$^$^$D$C$3$s$G$*$/!#(B
  (skk-num-rawnum-exp-1 string "[$B!;0l6e8^;0;M<7FsH,O;(B]+" "#2" 0))

(defun skk-num-rawnum-exp-1 (string key type place)
  (save-match-data
    (while (string-match key string)
      (setq string (concat (substring string 0 (match-beginning place))
			   type
			   (substring string (match-end place)))))
    string))

(defun skk-num-flatten-list (list)
  ;; $BM?$($i$l$?%j%9%H$N3FMWAG$+$iAH$_9g$;2DG=$JJ8;zNs$NO"@\$r:n$j!"%j%9%H$GJV(B
  ;; $B$9!#(B
  ;; (("A" "B") "1" ("X" "Y")) -> ("A1X" "A1Y" "B1X" "B1Y")
  (let ((dst (car list))
 	(src (cdr list))
 	elt)
    (while src
      (setq elt (car src))
      (if (consp elt)
 	  (setq dst (apply (function nconc)
 			   (mapcar
 			    (lambda (str0)
 			      (mapcar
 			       (lambda (str1)
 				 (concat str0 str1))
 			       elt))
 			    dst)))
 	(setq dst (mapcar
 		   (lambda (str0)
 		     (concat str0 elt))
 		   dst)))
      (setq src (cdr src)))
    dst))

(defun skk-num-exp (num type)
  ;; ascii $B?t;z$N(B NUM $B$r(B TYPE $B$K=>$$JQ49$7!"JQ498e$NJ8;zNs$rJV$9!#(B
  ;; TYPE $B$O2<5-$NDL$j!#(B
  ;; 0 -> $BL5JQ49(B
  ;; 1 -> $BA43Q?t;z$XJQ49(B
  ;; 2 -> $B4A?t;z$XJQ49(B ($B0L<h$j$J$7(B)
  ;; 3 -> $B4A?t;z$XJQ49(B ($B0L<h$j$r$9$k(B)
  ;; 4 -> $B$=$N?t;z$=$N$b$N$r%-!<$K$7$F<-=q$r:F8!:w(B
  ;; 5 -> $B4A?t;z(B ($B<j7A$J$I$G;HMQ$9$kJ8;z$r;HMQ(B) $B$XJQ49(B ($B0L<h$j$r$9$k(B)
  ;; 9 -> $B>-4}$G;HMQ$9$k?t;z(B ("$B#3;M(B" $B$J$I(B) $B$KJQ49(B
  (save-match-data
    (let ((fun (cdr (assq type skk-num-type-alist))))
      (if fun (funcall fun num)))))

(defun skk-num-jisx0208-latin (num)
  ;; ascii $B?t;z$N(B NUM $B$rA43Q?t;z$NJ8;zNs$KJQ49$7!"JQ498e$NJ8;zNs$rJV$9!#(B
  ;; $BNc$($P(B "45" $B$r(B "$B#4#5(B" $B$KJQ49$9$k!#(B
  (let ((candidate
         (mapconcat (function (lambda (c) (cdr (assq c skk-num-alist-type1))))
                    num "")))
    (if (not (string= candidate ""))
        candidate)))

(defun skk-num-type2-kanji (num)
  ;; ascii $B?t;z(B NUM $B$r4A?t;z$NJ8;zNs$KJQ49$7!"JQ498e$NJ8;zNs$rJV$9!#(B
  ;; $BNc$($P!"(B"45" $B$r(B "$B;M8^(B" $B$KJQ49$9$k!#(B
  (save-match-data
    (if (not (string-match "\\.[0-9]" num))
        (let ((candidate
               (mapconcat (function (lambda (c)
                                      (cdr (assq c skk-num-alist-type2))))
                          num "")))
          (if (not (string= candidate ""))
              candidate)))))

(defun skk-num-type3-kanji (num)
  ;; ascii $B?t;z(B NUM $B$r4A?t;z$NJ8;zNs$KJQ49$7(B ($B0L<h$j$r$9$k(B)$B!"JQ498e$NJ8;zNs$r(B
  ;; $BJV$9!#Nc$($P(B "1021" $B$r(B "$B@iFs==0l(B" $B$KJQ49$9$k!#(B
  (save-match-data
    (if (not (string-match "\\.[0-9]" num))
	;; $B>.?tE@$r4^$^$J$$?t(B
        (let ((str (skk-num-type3-kanji-1 num)))
          (if (string= "" str) "$B!;(B" str)))))

(defun skk-num-type3-kanji-1 (num)
  ;; skk-num-type3-kanji $B$N%5%V%k!<%A%s!#(B
  (let ((len (length num))
	(i 0)
        char v num1 v1)
    ;; $B!V@i5~!W$^$G$O=PNO$9$k!#(B
    (when (> len 20) (skk-error "$B0L$,Bg$-$9$.$^$9!*(B" "Too big number!"))
    (setq num (append num nil))
    (cond
     ((<= len 4)
      (while (setq char (car num))
	;; $B0L(B:   $B0l(B  $B==(B  $BI4(B  $B@i(B
	;; len:   1   2   3   4
	(if (= len 1)
	    ;; $B0L$rI=$o$94A?t;z0J30$N4A?t;z!#(B
	    (unless (eq char ?0)
	    ;; $B0l$N0L$G(B 0 $B$G$J$$?t!#(B
	      (setq v (concat v (cdr (assq char skk-num-alist-type2)))))
	  ;; $B0L$rI=$o$94A?t;z0J30$N4A?t;z!#(B
	  (unless (memq char '(?0 ?1))
	    ;; $B==$N0L0J>e$G!"$+$D(B 0, 1 $B0J30$N?t;z!#(B
	    (setq v (concat v (cdr (assq char skk-num-alist-type2)))))
	  ;; $B0L$rI=$o$94A?t;z!#(B
	  (when (and (not (eq char ?0)) (memq len '(2 3 4)))
	    (setq v
		  (concat
		   v
		   (cdr (assq len '((2 . "$B==(B") (3 . "$BI4(B") (4 . "$B@i(B"))))))))
	(setq len (1- len) num (cdr num))))
     (t
      (setq num (nreverse num))
      (while num
	(setq num1 nil)
	(while (and (< (length num1) 4) num)
	  (setq num1 (cons (car num) num1)
		num (cdr num)))
	(when num1
	  (setq v1 (skk-num-type3-kanji-1 num1))
	  (when (and (eq i 1) (equal v1 "$B@i(B"))
	    ;; $BF|K\8l$G$O!V@i2/!W$H$$$&I=8=$O$H$-$K;H$o$l$k$,!"!V@iK|!W$H$$$&I=(B
	    ;; $B8=$O$^$:;H$o$l$J$$$N$G!"!V0l@iK|!W$KD>$9!#(B
	    (setq v1 (concat "$B0l(B" v1)))
	  (setq
	   v
	   (concat
	    v1
	    (when v1
	      (cdr
	       (assq
		i '((0 . "") (1 . "$BK|(B") (2 . "$B2/(B") (3 . "$BC{(B") (4 . "$B5~(B")))))
	    v)))
	(setq i (1+ i)))))
    v))

(defun skk-num-type5-kanji (num)
  ;; ascii $B?t;z(B NUM $B$r4A?t;z$NJ8;zNs$KJQ49$7(B ($B0L<h$j$r$9$k(B)$B!"JQ498e$NJ8;zNs$r(B
  ;; $BJV$9!#Nc$($P(B "1021" $B$r(B "$B0motFu=&0m(B" $B$KJQ49$9$k!#(B
  (save-match-data
    (if (not (string-match "\\.[0-9]" num))
	;; $B>.?tE@$r4^$^$J$$?t(B
        (let ((str (skk-num-type5-kanji-1 num)))
          (if (string= "" str) "$BNm(B" str)))))

(defun skk-num-type5-kanji-1 (num)
  ;; skk-num-type5-kanji $B$N%5%V%k!<%A%s!#(B
  (let ((len (length num))
	(i 0)
         char v num1 v1)
    ;; $B!V@i5~!W$^$G$O=PNO$9$k!#(B
    (when (> len 20) (skk-error "$B0L$,Bg$-$9$.$^$9!*(B" "Too big number!"))
    (setq num (append num nil))
    (cond
     ((<= len 4)
      (while (setq char (car num))
	(if (= len 1)
	    (unless (eq char ?0)
	      (setq v (concat v (cdr (assq char skk-num-alist-type5)))))
	  ;; $B0L$rI=$o$94A?t;z0J30$N4A?t;z!#(B
	  (setq v (concat v (cdr (assq char skk-num-alist-type5))))
	  ;; $B0L$rI=$o$94A?t;z!#(B
	  (when (and (not (eq char ?0)) (memq len '(2 3 4)))
	    (setq v
		  (concat
		   v
		   (cdr (assq len '((2 . "$B=&(B") (3 . "$BI4(B") (4 . "$Bot(B"))))))))
	(setq len (1- len) num (cdr num))))
     (t
      (setq num (nreverse num))
      (while num
	(setq num1 nil)
	(while (and (< (length num1) 4) num)
	  (setq num1 (cons (car num) num1)
		num (cdr num)))
	(when num1
	  (setq v1 (skk-num-type5-kanji-1 num1))
	  (setq
	   v
	   (concat
	    v1
	    (when v1
	      (cdr
	       (assq
		i '((0 . "") (1 . "$Bh_(B") (2 . "$B2/(B") (3 . "$BC{(B") (4 . "$B5~(B")))))
	    v)))
	(setq i (1+ i)))))
    v))

(defun skk-num-shogi (num)
  ;; ascii $B?t;z$N(B NUM $B$r>-4}$G;HMQ$5$l$k?t;zI=5-$KJQ49$9$k!#(B
  ;; $BNc$($P(B "34" $B$r(B "$B#3;M(B" $B$KJQ49$9$k!#(B
  (save-match-data
    (if (and (= (length num) 2)
             (not (string-match "\\.[0-9]" num)))
        (let ((candidate
               (concat (cdr (assq (aref num 0) skk-num-alist-type1))
                       (cdr (assq (aref num 1) skk-num-alist-type2)))))
          (if (not (string= candidate ""))
              candidate)))))

(defun skk-num-recompute (num)
  ;; #4 $B$N8+=P$7$KBP$7!"(Bskk-henkan-key $B$KBeF~$5$l$??t;z$=$N$b$N$r:FEY8!:w$9$k!#(B
  (let (result)
    (setq skk-num-recompute-key num)
    (with-temp-buffer
      ;; $B%+%l%s%H%P%C%U%!$N%P%C%U%!%m!<%+%kJQ?t$K1F6A$r5Z$\$5$J$$$h$&!"%o!<%-(B
      ;; $B%s%0%P%C%U%!$X0lC6F($2$k(B
      (let ((skk-current-search-prog-list skk-search-prog-list)
            (skk-henkan-key num)
	    ;; $B%+%l%s%H$NJQ49$OAw$j$J$7(B (skk-henkan-okurigana $B$H(B skk-okuri-char $B$O(B
	    ;; $B$$$:$l$b(B nil) $B$@$,!"JL%P%C%U%!(B (work $B%P%C%U%!(B) $B$KF~$C$F$$$k$N$G!"G0(B
	    ;; $B$N$?$a!"(Bnil $B$rF~$l$F$*$/!#(B
            skk-henkan-okurigana skk-okuri-char skk-use-numeric-conversion)
        (while skk-current-search-prog-list
          (setq result (skk-nunion result (skk-search))))))
    ;; $B$3$3$G(B temp-buffer $B$r=P$FJQ49$r9T$J$C$F$$$k%+%l%s%H%P%C%U%!$KLa$k(B
    ;; ($B%P%C%U%!%m!<%+%kCM$G$"$k(B skk-henkan-list $B$rA`:n$7$?$$$?$a(B)$B!#(B
    (if result
        (if (null (cdr result));;(= (length result) 1)
            (car result)
          result)
      ;; $BJQ49$G$-$J$+$C$?$i85$N?t;z$r$=$N$^$^JV$7$F$*$/!#(B
      num)))

;;;###autoload
(defun skk-num-uniq ()
  (if (or (not skk-num-uniq) (null skk-henkan-list))
      nil
    (save-match-data
      (let ((n1 -1) n2 e1 e2 e3
            ;; 1 $B$D$G$b(B 2 $B7e0J>e$N?t;z$,$"$l$P!"(B#2 $B$H(B #3 $B$G$O(B uniq $B$7$J$$!#(B
            (type2and3 (> 2 (apply 'max (mapcar 'length skk-num-list))))
            type2 type3 index2 index3 head2 head3 tail2 tail3
            case-fold-search)
        (while (setq n1 (1+ n1) e1 (nth n1 skk-henkan-list))
          ;; cons cell $B$G$J$1$l$P(B skk-nunion $B$G=hM}:Q$_$J$N$G!"=EJ#$O$J$$!#(B
          (if (consp e1)
              (setq skk-henkan-list (delete (car e1) skk-henkan-list)
                    skk-henkan-list (delete (cdr e1) skk-henkan-list)))
          (if (not (and skk-num-recompute-key (consp e1)))
              nil
            ;; ("#4" . "xxx") $B$r4^$`8uJd$,(B skk-henkan-list $B$NCf$K$"$k!#(B
            (setq n2 -1)
            (while (setq n2 (1+ n2) e2 (nth n2 skk-henkan-list))
              (if (and (not (= n1 n2)) (consp e2)
                       ;; $BNc$($P(B ("#4" . "$B0l(B") $B$H(B ("#2" . "$B0l(B") $B$,JBB8$7$F$$(B
                       ;; $B$k>l9g!#(B
                       (string= (cdr e1) (cdr e2)))
                  (setq skk-henkan-list (delq e2 skk-henkan-list)))))
          (if (not type2and3)
              nil
            ;; 1 $B7e$N?t;z$rJQ49$9$k:]$K!"(Bskk-henkan-list $B$K(B #2 $B%(%s%H%j$H(B #3
            ;; $B%(%s%H%j$,$"$l$P!"(B#2 $B$b$7$/$O(B #3 $B%(%s%H%j$N$&$A!"$h$j8eJ}$K$"$k(B
            ;; $B$b$N$r>C$9!#(B
            (setq e3 (if (consp e1) (car e1) e1))
            ;; e3 $B$O(B "#2" $B$N$h$&$K?tCMJQ49$r<($9J8;zNs$N$_$H$O8B$i$J$$$N$G!"(B
            ;; member $B$O;H$($J$$!#(B
            (cond ((string-match "#2" e3)
                   (setq type2 e1
                         index2 n1
                         head2 (substring e3 0 (match-beginning 0))
                         tail2 (substring e3 (match-end 0))))
                  ((string-match "#3" e3)
                   (setq type3 e1
                         index3 n1
                         head3 (substring e3 0 (match-beginning 0))
                         tail3 (substring e3 (match-end 0)))))))
        (if (and type2and3 type2 type3
                 ;; $B?tCMJQ49$r<($9J8;zNs(B "#[23]" $B$NA08e$NJ8;zNs$bF10l$N$H(B
                 ;; $B$-$N$_(B uniq $B$r9T$J$&!#(B
                 (string= head2 head3) (string= tail2 tail3))
            (if (> index2 index3)
                ;; "#3" $B$NJ}$,A0$K$"$k!#(B
                (setq skk-henkan-list (delq type2 skk-henkan-list))
              ;; $BJQ?t(B type[23] $B$NCM$O!"(Bskk-henkan-list $B$+$iD>@\Cj=P$7$?$b(B
              ;; $B$N$@$+$i(B delete $B$G$J$/!"(Bdelq $B$G==J,!#(B
              (setq skk-henkan-list (delq type3 skk-henkan-list))))))))

;;;###autoload
(defun skk-num-initialize ()
  ;; skk-use-numeric-convert $B4XO"$NJQ?t$r=i4|2=$9$k!#(B
  (setq skk-last-henkan-data
	(put-alist 'num-list skk-num-list skk-last-henkan-data)
	skk-num-list nil
        skk-num-recompute-key nil))

;;;###autoload
(defun skk-num-henkan-key ()
  ;; type4 $B$N?tCM:FJQ49$,9T$J$o$l$?$H$-$O!"?tCM<+?H$rJV$7!"$=$l0J30$N?tCMJQ49(B
  ;; $B$G$O!"(Bskk-henkan-key $B$rJV$9!#(B
  (or skk-num-recompute-key skk-henkan-key))

;;;###autoload
(defun skk-num-update-jisyo (noconvword word &optional purge)
  ;; $B?t;z<+?H$r8+=P$78l$H$7$F<-=q$N%"%C%W%G!<%H$r9T$J$&!#(B
  (if (and skk-num-recompute-key
           (save-match-data (string-match "#4" noconvword)))
      (with-current-buffer (skk-get-jisyo-buffer skk-jisyo 'nomsg)
	(let ((skk-henkan-key skk-num-recompute-key)
	      skk-use-numeric-conversion)
	  ;;(message "%S" skk-num-recompute-key)
	  (skk-update-jisyo word purge)))))

;;;###autoload
(defun skk-num (str)
  ;; $B?t;z$r(B skk-number-style $B$NCM$K=>$$JQ49$9$k!#(B
  ;; skk-current-date $B$N%5%V%k!<%A%s!#(B
  (mapconcat (function
	      (lambda (c)
		(if (and (>= ?9 c) (>= c 0))
		    (cond ((or (not skk-number-style)
			       (and (numberp skk-number-style)
				    (= skk-number-style 0)))
			   (char-to-string c))
			  ((or (eq skk-number-style t)
			       (and (numberp skk-number-style)
				    (= skk-number-style 1)))
			   (cdr (assq c skk-num-alist-type1)))
			  (t (cdr (assq c skk-num-alist-type2)))))))
	     str ""))

(defadvice skk-kakutei-initialize (after skk-num-ad activate)
  (and (skk-numeric-p) (skk-num-initialize)))

(run-hooks 'skk-num-load-hook)

(require 'product)
(product-provide (provide 'skk-num) (require 'skk-version))
;;; Local Variables:
;;; End:
;;; skk-num.el ends here
