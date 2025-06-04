# pet-diag-rom

A simple dianostics ROM for Commodore PET computers.

## Building

```bash
sudo apt install cc65 vice
./build.sh
```

## Running

Write ```f000-rom.bin``` to an EPROM and insert in the PET's top ROM socket.

Displays the first 8 bytes of each of the ROMs:

![Screenshot of the diagnostic ROM output](docs/images/diag-rom.png)
