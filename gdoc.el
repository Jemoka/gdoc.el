;;;; gdoc.el --- A dead simple gdrive wrapper

;; Copyright (C) 2021 Houjun Liu

;; Author: Houjun Liu <hliu@shabang.cf>
;; URL: http://github.com/jemoka/gdoc.el
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience docs google extensions
;;
;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This program is a wrapper of gdrive for the sole purpose of editing
;; google drive files in plaintext.
;;
;; Begin by installing `gdrive` from your favourite package manager
;; and authenticating to it by executing `gdrive list`.
;;
;; Once authenticated, `M-x gdoc-edit` allows the editing of a doc

;;; Code:

(require 'subr-x)

(defun completing-search-gdoc-file ()
  "Search Google Docs files with Autocomplete"
  (let* ((files (mapcar (lambda (n)
			  (mapcar #'string-trim 
				  (seq-filter (lambda (j) (not (string= j "")))
					      (split-string n "   "))))
			(cdr (split-string (shell-command-to-string (format "gdrive list -q \"name contains '%s'\"" (read-string "Docs Search Term: "))) "\n"))))
	 (names (mapcar #'cadr files))
	 (name (completing-read "Open: " names)))
    (list name (car (nth (cl-position name names) files)))))

(defun async-shell-command-no-window (command)
  "YOINK: https://stackoverflow.com/questions/13901955/how-to-avoid-pop-up-of-async-shell-command-buffer-in-emacs"
  (interactive)
  (let
      ((display-buffer-alist
	(list
	 (cons
	  "\\*Async Shell Command\\*.*"
	  (cons #'display-buffer-no-window nil)))))
    (async-shell-command
     command)))


(defun load-gdoc-by-id-and-name (id name)
  "Load Google doc by name and ID"
  (let ((default-directory temporary-file-directory))
    (shell-command (format "gdrive export --mime text/plain %s" id))
    (rename-file (format "%s.conf" name) name t)
    (find-file name)
    (add-hook 'after-save-hook
	      (apply-partially
	       (lambda (id name)
		 (async-shell-command-no-window (format "gdrive update %s %s" id name)))
	       id name)
	      nil t)))

(defun gdoc-edit ()
  (interactive)
  (let ((doc (completing-search-gdoc-file)))
    (load-gdoc-by-id-and-name (cadr doc) (car doc))))

(provide 'gdoc)
;;; gdoc.el ends here
