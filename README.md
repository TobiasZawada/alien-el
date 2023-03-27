# alien-el
Execute Elisp code within comments of buffers for other programming languages.

Documented example:

```lang-cpp
// Setting local variables works.
// The Elisp code starts with the following marker:
// elisp-start: (setq-local fishy t)
// elisp-end
//< The marker for the end of the Elisp form and its output.
int main() {
	// Blocks of line-comments work.
	// If the form evaluates to a string
	// that string is inserted after the comment containing the
	// end of the sexp.
	//
	// elisp-start:
	// (concat
	//  (format
	//    "\tprint(\"Something %s"
	//    (if fishy "fishy" "normal"))
	//  ".\");\n")
	print("Something fishy.");
// elisp-end
	//< Marker for the end of the output.


/*
  Elisp code can also be wrapped by block comments.
  elisp-start:
  (concat
  (format
  "\n\tprint(\"Something %s"
  (if fishy "fishy" "normal"))
  "\");\n")
*/
	print("Something fishy");
/* elisp-end */
} // End of main.
```

