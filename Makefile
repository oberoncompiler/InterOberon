
all: InterOberon

InterOberon: *.Mod
	fob InterOberon.Mod

run: all
	./InterOberon Hello.Mod

clean:
	rm -rf _Build InterOberon

.PHONY: run clean
