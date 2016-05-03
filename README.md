# ZX Spectrum 128K for [MIST Board](https://github.com/mist-devel/mist-board/wiki)

Some verilog models from Till Harbaum [Spectrum](https://github.com/mist-devel/mist-board/tree/master/cores/spectrum) core were used in this project.

### Features:
- Fully functional ZX Spectrum 48K, 128K and Pentagon 128 with correct CPU and Video timings
- Turbo 7MHz, 14MHz, 28MHz, 56MHz.
- DivMMC with [ESXDOS](http://www.esxdos.org/) (TAP, TRD, SNA files)
- Original Tape loading through OSD (CSW files)
- TR-DOS and native TRD images (read-only)
- Native TAP with turbo loading.

### Installation:
Copy the *.rbf file at the root of the SD card. You can rename the file to core.rbf if you want the MiST to load it automatically at startup.
Copy [spectrum.rom](https://github.com/sorgelig/ZX_Spectrum-128K_MIST/tree/master/releases/spectrum.rom) file to the root of SD card.

For PAL mode (RGBS output) you need to put [mist.ini](https://github.com/sorgelig/ZX_Spectrum-128K_MIST/tree/master/releases/mist.ini) file to the root of SD card. Set the option **scandoubler_disable** for desired video output.

For ESXDOS functionality you need to put SYS and BIN folders from [esxdos085.zip](http://www.esxdos.org/files/esxdos085.zip) to the root of SD card.
First press of F11 key will load and initialize ESXDOS, subsequent presses will open ESXDOS manager.

Press F12 to access OSD menu, 
F11 for ESXDOS, Ctrl+F11 for warm reset, Alt+F11 for cold reset (this will turn ESXDOS off, unload TRD).

### Notes about supported formats:
**TRD** images are supported through ESXDOS in read and write modes. New versions of core support TRD natively though TR-DOS as well, thus ESXDOS is not required if read-only mode is enough. To use TR-DOS you need to choose TRD image in OSD first. ESXDOS (F11 key) will be blocked till cold reset or core reload. In ZX48 mode use command **RANDOMIZE USR 15616** to enter TR-DOS. Use command **RETURN** to leave TR-DOS.

**TAP** files are supported through ESXDOS. New versions of core support TAP natively through OSD, thus ESXDOS isn't required. Also it allows to use long file names. It is possible to use normal and **turbo** loading (only if application uses standard loading routines from ROM). To load in turbo mode, you need to choose TAP file in OSD **first** and then start to load app through menu (ZX128) or by command **LOAD ""** (ZX48, ZX128). To load TAP file in normal mode through internal AUDIO IN loop, you need to start loading through menu or command **first** and then choose TAP file though OSD. If application uses non-standard loader, then TAP file will be played in normal mode automatically. Thus it's safe to always choose the turbo mode. Some applications are split into several parts inside one TAP file. For example DEMO apps where each part is loaded after finish of previous part, or games loading levels by requests. The core pauses the TAP playback after each code part (flag=#255). If application uses standard loader from ROM, then everything will be handled automatically and unnoticeable. If app uses non-standard loader, then there is no way to detect the loading. In this case you need to press **F1 key** to continue/pause TAP playback. Do not press F1 key while data is loading (or you will have to reset and start from beginning). To help operate with TAP (for non-standard loaders) there is special yellow LED signaling:
- LED is ON: more data is available in TAP file.
- LED is flashing: loading is in process.
- LED is OFF: no more data left in TAP file.

In normal mode, while TAP loading, the following keys can be used:
- F1 - pause/continue
- F2 - jump to previous part (if pressed while pilot tone), or beginning of current part (if pressed while code is transferring).
- F3 - skip to next part

**CSW** files are supported and always loaded in normal mode. This format is useful only for apps using non-standard loaders with non-standard transfer speeds. Can use F1 key to pause/continue.

### Turbo modes
You can control CPU speed by following keys:
- F4 - normal speed (3.5MHz)
- F5 - 7MHz
- F6 - 14MHz
- F7 - 28MHz
- F8 - 56MHz

It's useful to switch to maximum speed when you are loading tape in normal mode. Due to SDRAM speed limitation 28MHz and 56MHz speeds include wait states, so effective CPU speed is lower than nominal.

### Download precompiled binaries and system ROMs:
Go to [releases](https://github.com/sorgelig/ZX_Spectrum-128K_MIST/tree/master/releases) folder.
