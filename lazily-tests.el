;;; lazily-tests.el --- Tests for lazily.el

;; Copyright (C) 2017 Justin Burkett

;; Author: Justin Burkett <justin@burkett.cc>
;; Homepage: https://github.com/justbur/emacs-lazily
;; Version: 0.0.0

;; This file is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3, or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
;; A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
;;
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'lazily)
(require 'ert)

(ert-deftest lazily-tests-check-do-all-form-processing ()
  "Check that `lazily-do-all' uses `lazily--bad-forms' correctly."
  (let (lazily--bad-forms after-load-functions)
    (setq lazily-tests-good-list '(1))
    (defun lazily-tests-good-func () nil)
    (unintern 'lazily-tests-bad-list obarray)
    (unintern 'lazily-tests-bad-func obarray)
    ;; (message "0:\n%s" lazily--bad-forms)
    (lazily-do-all
     (add-to-list 'lazily-tests-good-list 2)
     (add-to-list 'lazily-tests-bad-list 2)
     (lazily-tests-good-func)
     (lazily-tests-bad-func))
    ;; (message "1:\n%s" lazily--bad-forms)
    (should
     (equal lazily--bad-forms
            '((((add-to-list 'lazily-tests-bad-list 2)
                (void-variable lazily-tests-bad-list)
                nil))
              (((lazily-tests-bad-func)
                (void-function lazily-tests-bad-func)
                nil)))))
    (defun lazily-tests-bad-func () nil)
    (lazily--redo)
    ;; (message "2:\n%s" lazily--bad-forms)
    (should
     (equal lazily--bad-forms
            '((((add-to-list 'lazily-tests-bad-list 2)
                (void-variable lazily-tests-bad-list)
                nil)))))
    (setq lazily-tests-bad-list '(1))
    (lazily--redo)
    ;; (message "3:\n%s" lazily--bad-forms)
    (should (null lazily--bad-forms))))

(ert-deftest lazily-tests-check-do-form-processing ()
  "Check that `lazily-do' uses `lazily--bad-forms' correctly."
  (let (lazily--bad-forms after-load-functions)
    (setq lazily-tests-good-list '(1))
    (defun lazily-tests-good-func () nil)
    (unintern 'lazily-tests-bad-list obarray)
    (unintern 'lazily-tests-bad-func obarray)
    (lazily-do
     (add-to-list 'lazily-tests-good-list 2)
     (add-to-list 'lazily-tests-bad-list 2)
     (lazily-tests-good-func)
     (lazily-tests-bad-func))
    ;; (message "1:\n%s" lazily--bad-forms)
    (should
     (equal lazily--bad-forms
            '((((add-to-list 'lazily-tests-bad-list 2)
                (void-variable lazily-tests-bad-list) nil)
               ((lazily-tests-good-func))
               ((lazily-tests-bad-func))))))
    (defun lazily-tests-bad-func () nil)
    (lazily--redo)
    ;; (message "2:\n%s" lazily--bad-forms)
    (should
     (equal lazily--bad-forms
            '((((add-to-list 'lazily-tests-bad-list 2)
                (void-variable lazily-tests-bad-list) nil)
               ((lazily-tests-good-func))
               ((lazily-tests-bad-func))))))
    (setq lazily-tests-bad-list '(1))
    (lazily--redo)
    ;; (message "3:\n%s" lazily--bad-forms)
    (should (null lazily--bad-forms))))

(ert-deftest lazily-tests-check-do-form-processing-2 ()
  "Check that `lazily-do' uses `lazily--bad-forms' correctly."
  (let (lazily--bad-forms after-load-functions)
    (setq lazily-tests-good-list '(1))
    (defun lazily-tests-good-func () nil)
    (unintern 'lazily-tests-bad-list obarray)
    (unintern 'lazily-tests-bad-func obarray)
    (lazily-do
     (add-to-list 'lazily-tests-good-list 2)
     (add-to-list 'lazily-tests-bad-list 2)
     (lazily-tests-good-func)
     (lazily-tests-bad-func))
    (should
     (equal lazily--bad-forms
            '((((add-to-list 'lazily-tests-bad-list 2)
                (void-variable lazily-tests-bad-list) nil)
               ((lazily-tests-good-func))
               ((lazily-tests-bad-func))))))
    (setq lazily-tests-bad-list '(1))
    (lazily--redo)
    ;; (message "2:\n%s" lazily--bad-forms)
    (should
     (equal lazily--bad-forms
            '((((lazily-tests-bad-func)
                (void-function lazily-tests-bad-func)
                nil)))))
    (defun lazily-tests-bad-func () nil)
    (lazily--redo)
    (should (null lazily--bad-forms))))
