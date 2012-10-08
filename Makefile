
all:
	sphinx-build -b html . ./html
	echo "firefox ./html/readme.html"
