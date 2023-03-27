;;; alien-el.el --- Execute Elisp code in comments   -*- lexical-binding: t; -*-

;; Copyright (C) 2023  DREWOR020

;; Author: DREWOR020 <toz@smtp.1und1.de>
;; Keywords: languages, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(defcustom alien-el-start "elisp-start:"
  "Marker for elisp form in comments.
The sexp following this maker is executed."
  :group 'alien-el
  :type 'string)

(defcustom alien-el-end "elisp-end"
  "Marker for end of elisp result."
  :group 'alien-el
  :type 'string)

(defcustom alien-el-lexical t
  "Evaluate code lexical."
  :group 'alien-el
  :type 'boolean
  )

(defun alien-el-comment-start-position ()
  "The position of the start of the current comment, or nil."
  (save-excursion
    (comment-beginning)))

(defun alien-el-comment-end-position ()
  "The position of the end of the current comment, or nil.
That is either the end of the available portion of the buffer
or the position after the closing comment characters.
For a line comment it returns the position after the newline
character if there is one otherwise it returns `point-max'."
  (save-excursion
    (goto-char (comment-beginning))
    (comment-forward)
    (point)))

(defun alien-el-line-comment-p ()
  "Point is within a line comment."
  (let ((end (alien-el-comment-end-position)))
    (or
     (eq end (1+ (buffer-size)))
     (eq (char-before end) ?\n))))

(defun alien-el-only-line-comment-p ()
  "Current line is only a comment line.
There might be some leading whitespace."
  (save-excursion
    (beginning-of-line)
    (and
     (comment-search-forward (line-end-position) t)
     (alien-el-line-comment-p)
     (comment-only-p (line-beginning-position) (line-end-position)))))

(defun alien-el-find-comment-block ()
  "Find next comment block and return (beg . end).
A comment block can be a block comment or
a consecutive sequence of comment lines."
  (let (beg end line-comments)
    (save-excursion
      (setq beg (comment-search-forward (point-max) t))
      (when beg
	(goto-char beg)
	(while (and
		(setq end (point))
		(alien-el-only-line-comment-p)
		(eq (forward-line) 0))
	  (setq line-comments t))
	(if line-comments
	    (backward-char)
	  (goto-char end)
	  (comment-forward))
	(setq end (point))))
    (when beg
      (goto-char beg)
      (cons beg end))))

;;;###autoload
(defun alien-el-exec ()
  "Run elisp code in comments of current buffer.
The elisp code is marked by `alien-el-start'.

The result follows the comment up to a comment
marked by `alien-el-end'."
  (interactive)
  (comment-normalize-vars)
  (save-excursion
    (let (beg-end beg end code code-lines
		  (mode major-mode))
      (goto-char (point-min))
      (while (setq beg-end (alien-el-find-comment-block))
	(setq end (cdr beg-end))
	(when (setq beg (search-forward alien-el-start end 'noerror))
	  (let* ((str (buffer-substring-no-properties beg end))
		 ret)
	    (with-temp-buffer
	      (insert str)
	      (goto-char (point-min))
	      (forward-line)
	      (funcall mode)
	      (uncomment-region (point) (point-max))
	      (goto-char (point-min))
	      (setq code (read (current-buffer))
		    code-lines (count-lines (point-min) (point))))
	    (setq ret (eval code))
	    (goto-char beg)
	    ;; Overwrite the old result with the new one:
	    (when (alien-el-only-line-comment-p)
	      (forward-line (1- code-lines));;< Line with the end of code.
	      (end-of-line)
	      )
	    (goto-char (alien-el-comment-end-position))
	    (setq beg (point))
	    ;; Search for the marker `alien-el-end':
	    (setq end nil)
	    (while (and (null end)
			(setq beg-end (alien-el-find-comment-block)))
	      (when (search-forward alien-el-end (cdr beg-end) 'noerror)
		(goto-char (comment-beginning))
		(setq end (point))))
	    (unless end
	      (user-error "Cannot find end of output for alien el block"))
	    (when (stringp ret)
	      (delete-region beg end)
	      (insert ret))))))))

(provide 'alien-el)
;;; alien-el.el ends here
