TRS80_LDOS_KIFG
===============

French/German version of KI/DVR for TRS-80 Model III/4, LDOS 5.3
----------------------------------------------------------------

**KI/DVR International version for LDOS 5.3 - Version 0.3**

Original QWERTY version (c) 1991 MISOSYS, Inc.

International version (c) 2023 GmEsoft.

Build using [George Phillips' ZMAC](http://www.48k.ca/zmac.html):

`ZMAC KIFG.ASM [-P1=1|-P2=1] -o KIFG.CMD -o KIFG.LST -o KIFG.BDS -c -g --mras`

with:
  - `-P1=1` for the AZERTY French version
  - `-P2=1` for the QWERTZ German version

Then rename `KIFG.CMD` to `KIFR.DVR` or `KIGR.DVR` .

To load in LDOS 5.3:
- `SET *KI KIFR` for the AZERTY French version
- `SET *KI KIGR` for the QWERTZ German version

*Pre-release (tag v0.3-alpha in the Releases section.*
