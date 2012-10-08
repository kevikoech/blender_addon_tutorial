
all:
	sphinx-build -b html ~/doc ~/doc/html
	echo "firefox ~/doc/html/readme.html"
