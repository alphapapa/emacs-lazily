;;; lazily.el --- lazily configure Emacs

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

;; This package simply provides the macro `lazily-do' for use in Emacs
;; configuration files.  It only does one thing.  You can wrap any configuration
;; steps in the macro without having to worry about void variable messages or
;; void variable messages.  In the example below good-list is declared, but
;; Emacs doesn't know about bad-list yet.  This will throw a void-variable
;; error.

;; (defvar good-list nil)
;; (lazily-do
;;  (add-to-list 'good-list 1)
;;  (add-to-list 'bad-list 1))

;; We have a couple of options here.  We could figure out which library defines
;; bad-list and use `with-eval-after-load' like this.

;; (with-eval-after-load 'bad-library
;;  (add-to-list 'bad-list 1))

;; We could also explicitly require bad-library, which might be slow, or
;; something else.  The way `lazily-do' works is it stores the forms in a list
;; and tries again to eval those forms (in order) every time a new library is
;; loaded.  It accomplishes this through using the `after-load-functions' hook.

;; To illustrate, suppose we had the original example in our config.  The form
;; with good-list will execute fine and there will be no difference to having
;; this form at the top level.  The one with bad-list throws a void-variable
;; error which is caught and the form is saved for later.  We do some work and
;; eventually something calls or loads bad-library.  This fires `lazily--redo'
;; to try the saved forms again, and now that bad-list is defined the original
;; error goes away and everything is dandy.

;;; Code:

(require 'pp)

(defgroup lazily nil
  "Lazily configure Emacs"
  :group 'startup)

(defcustom lazily-is-quiet t
  "If nil, log failed forms in message buffer."
  :type 'boolean
  :group 'lazily)

(defvar lazily--bad-forms nil
  "Forms currently with void variables or functions. Each sub
list takes the form \(FORM ERROR-DATA FILE\). ERROR-DATA is from
condition-case, and FILE is the file being loaded when the error
is encountered. ")

(defun lazily--redo (&rest _)
  "Try to execute all forms in `lazily--bad-forms'.

Any forms that throw void-variable or void-function errors are
kept in `lazily--bad-forms' to be tried again later."
  (let (still-bad)
    (while lazily--bad-forms
      (let* ((bad-form-list (pop lazily--bad-forms))
             (form (nth 0 bad-form-list))
             (prev-error-data (nth 1 bad-form-list))
             (file (nth 2 bad-form-list)))
        (if (or (and (eq (car prev-error-data) 'void-variable)
                     (boundp (cadr prev-error-data)))
                (and (eq (car prev-error-data) 'void-function)
                     (fboundp (cadr prev-error-data))))
            (condition-case error-data
                (eval form)
              ((void-function void-variable)
               (push (list form error-data nil) still-bad)))
          (push bad-form-list still-bad))))
    (if (null still-bad)
        (remove-hook 'after-load-functions 'lazily--redo)
      (setq lazily--bad-forms (nreverse still-bad)))))

(defun lazily--log (error-data form)
  "Print log message about bad form if enabled."
  (unless lazily-is-quiet
    (message "lazily: Found void (unknown) %s `%s' in form
        %s"
             (if (eq (car error-data) 'void-variable)
                 "variable" "function")
             (car (cdr-safe error-data))
             (pp-to-string form))))

(defun lazily-report ()
  "Produce report of bad forms found."
  (interactive)
  (let ((buffer (get-buffer-create "*lazily-report*")))
    (with-current-buffer buffer
      (erase-buffer)
      (insert "lazily found the following errors in forms:\n\n")
      (dolist (form-data lazily--bad-forms)
        (let ((file (nth 2 form-data))
              (err  (car (nth 1 form-data)))
              (sym  (nth 1 (nth 1 form-data)))
              (form (nth 0 form-data)))
          (insert (format "[%s] %s %s found in form\n  %s\n"
                          (or file "unknown file")
                          (or (replace-regexp-in-string
                               "-" " " (symbol-name err))
                               "unknown error for")
                          (or sym "unknown symbol")
                          (pp-to-string form))))))
    (switch-to-buffer-other-window buffer)
    (local-set-key "q" 'delete-window)))

;;;###autoload
(defmacro lazily-do (&rest forms)
  "Eval FORMS catching void-variable or void-function errors.

Any forms that throw void-variable or void-function errors are
stored in `lazily--bad-forms' to be tried again later.
Specifically, a `after-load-functions' hook is added to try and
execute these bad forms again after a new feature is loaded."
  (let ((wrapped-forms
         (mapcar
          (lambda (form)
            `(condition-case error-data
                 ,form
               ((void-variable void-function)
                (lazily--log error-data ',form)
                (push (list ',form error-data load-file-name)
                      error-forms))))
          forms)))
    `(let (error-forms)
       ,@wrapped-forms
       (setq lazily--bad-forms
             (append lazily--bad-forms
                     (nreverse error-forms)))
       (add-hook 'after-load-functions #'lazily--redo))))

(provide 'lazily)
;;; lazily.el ends here
