ca65 main.s -o main.o
ca65 data.s -o data.o
ld65 -o f000-rom.bin -C link.cfg main.o data.o