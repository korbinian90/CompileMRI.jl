INSTALLATION INSTRUCTIONS FOR MACOS
===================================

These are command line programs. They live in the "bin" folder next to this
file: romeo, clearswi, mcpc3ds, makehomogeneous and romeo_mask.

Pick the archive that matches your Mac:
  mritools_macos_arm64_*   Apple Silicon (M1 and newer)
  mritools_macos_x64_*     Intel
If you are unsure, click the Apple menu, then "About This Mac", and look at
"Chip" or "Processor".

Each one is offered as .tar.xz and .tar.gz. They contain the same files; the
.tar.xz is about 40% smaller to download and macOS unpacks it with the same
command.


RECOMMENDED: EXTRACT IN THE TERMINAL
------------------------------------

Extracting with the "tar" command does not mark the files, so the programs are
ready to use with no further steps.

1. Open the "Terminal" app (Command+Space, type "Terminal").

2. Type "cd " (with a space at the end), then drag the folder containing the
   downloaded archive (usually "Downloads") into the Terminal window. This
   fills in the correct path for you. Press Enter.

3. Paste the following, correcting the file name if it differs, then press
   Enter:

   tar -xf mritools_macos_arm64_4.8.0.tar.xz

4. Run a program to check it works:

   cd mritools_macos_arm64_4.8.0/bin
   ./romeo --help


IF YOU EXTRACTED BY DOUBLE CLICKING INSTEAD
-------------------------------------------

Then macOS has flagged every extracted file as quarantined and will refuse to
run them. Clear the flag for the whole folder at once:

1. Open the "Terminal" app.

2. Paste the following command, but DO NOT press Enter yet.
   Make sure there is a space at the end:

   xattr -cr 

3. Drag the extracted mritools folder into the Terminal window. This fills in
   the correct path for you.

4. Press Enter.

   (Why is this needed? macOS attaches a "quarantine" flag to everything that
   comes from the internet. Programs signed with a paid Apple developer
   certificate are allowed through automatically; these are not, so macOS
   blocks them until the flag is removed. The command clears the flag on the
   folder you dragged in and nothing else.)

If step 4 reports "Permission denied" or "Operation not permitted", repeat it
with "sudo xattr -cr " instead and enter your Mac password.


NOTES
-----

The programs are signed ad hoc, which is what lets them run at all on Apple
Silicon. It is not the same as a paid Apple developer signature, so the
quarantine flag above still has to be dealt with when it is present.

Each program is built for one architecture only. Running the Intel build on
Apple Silicon works through Rosetta 2 but is slower, so prefer the arm64
archive on those machines.

Problems: https://github.com/korbinian90/CompileMRI.jl/issues
