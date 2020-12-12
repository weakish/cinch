include config.mk

cinch: cinch.go
	@go build

install:
	@mkdir -p ${PREFIX}/bin
	@install cinch  ${PREFIX}/bin

uninstall:
	@rm -f ${PREFIX}/bin/cinch

clean:
	@rm -f cinch