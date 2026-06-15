BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
SRC    := openid-connect-enterprise-extensions-1_0.md
XML    := openid-connect-enterprise-extensions-1_0.xml
HTML   := openid-connect-enterprise-extensions-1_0.html

.PHONY: all html xml clean

all: html

html: $(HTML)

$(HTML): $(XML)
	mkdir -p html
	xml2rfc --html $(XML) --out $(HTML)

$(XML): $(SRC)
	mmark $(SRC) > $(XML)

clean:
	rm -f $(XML) $(HTML)
