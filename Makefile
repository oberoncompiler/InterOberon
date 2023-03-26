
all: InterOberon

InterOberon: *.Mod
	clear
	fob InterOberon.Mod

run: all
	./InterOberon Examples/Factorize.Mod

clean:
	rm -rf _Build InterOberon

.PHONY: run clean
