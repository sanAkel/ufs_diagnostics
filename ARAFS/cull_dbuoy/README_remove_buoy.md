Read through the following and please follow the steps listed below in the order they appear.

# Steps:
0. Log on to WCOSS-2. Full path to "this" txt file: /u/santha.akella/large_fs/README_remove_buoy.md

1. Get the source code. <-- THIS IS THE HEAVY LIFT.
git clone git@github.com:sanAkel/ufs_diagnostics.git

---

1. Get the prepbufr data files into a path like: /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr
   <-- THEY ARE YOUR INPUT FILES.
a. cd ufs_diagnostics/ARAFS/cull_dbuoy
b. Use `./stage_prepbufr.sh` to copy files from prod. For a past date, you need to do SOMETHING to get them (HPSS? or WHATEVER- it is your prooblem, go figure!)
   Example usage:
   ./stage_prepbufr.sh /lfs/h2/emc/global/noscrub/emc.global/dump /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr 202605
   If you provide no inputs, script will echo example usage and exit.

---

2. Build and install NCEPLIBS-bufr
a. git clone git@github.com:NOAA-EMC/NCEPLIBS-bufr.git
b. Load a modules for gcc and cmake: ml gcc/12.1.0 cmake/3.27.9
c. Build:
   bufr_path="/lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold"
   cmake -S NCEPLIBS-bufr -B NCEPLIBS-bufr/build -DCMAKE_INSTALL_PREFIX=$bufr_path/install -DMASTER_TABLE_DIR=$bufr_path/table
   cmake --build NCEPLIBS-bufr/build -j4
   ctest --test-dir NCEPLIBS-bufr/build
   cmake --install NCEPLIBS-bufr/build

---

3. Compile utility that removes drifting buoys, leaving everything else as-is in the prepbufr.
a. cd ufs_diagnostics/ARAFS/cull_dbuoy
b. gfortran prepbufr_no_dbuoy.F90 -o /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/ufs_diagnostics/ARAFS/cull_dbuoy/no_dbuoy.x /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/install/lib64/libbufr_4.a
   Adjust above paths as needed in your case.

---

4. Run the utility (from step 3) using process_and_verify.sh
a. cd ufs_diagnostics/ARAFS/cull_dbuoy
b. If you provide no inputs, script will echo example usage and exit, like shown below.
   ./process_and_verify.sh 
   Error: Exactly 5 arguments are required.
   Usage: ./process_and_verify.sh <INPUT_DIR> <OUTPUT_DIR> <DATE> <CULLER_EXE> <BINV_EXE>
   Example: ./process_and_verify.sh /path/to/prepbufr/20260501 /path/to/no_dbuoy/20260501 20260501 /path/to/no_dbuoy.x /path/to/binv
    --- 
   I ran it like the following:
   ./process_and_verify.sh /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr/20260501 /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/no_dbuoy/20260501 20260501 . /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/install/bin    

   ./process_and_verify.sh /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr/20260501 /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/no_dbuoy/20260501 20260501 /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/ufs_diagnostics/ARAFS/cull_dbuoy/no_dbuoy.x /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/install/bin/binv

>> All goes well, you can get an output similar to what I got:

```
------------------------------------------------------------
Starting One-Pass Precision Filter: 20260501
------------------------------------------------------------

[Cycle 00z]
   [STDOUT] Filter: Inspecting Surface Categories for 564s...
   ---------------------------------------------------------
   CULL RESULTS FOR: /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr/20260501/gdas.t00z.prepbufr
   Total Surface Reports Scanned:       224527
   Drifting Buoys (564) DROPPED:          5046
   Reports (Ships/Etc) PRESERVED:       219481
   ---------------------------------------------------------
  Verification (Final Counts):
SFCSHP           256         52861        2181176      206.49
TOTAL           7696       1090757      101190102

[Cycle 06z]
   [STDOUT] Filter: Inspecting Surface Categories for 564s...
   ---------------------------------------------------------
   CULL RESULTS FOR: /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr/20260501/gdas.t06z.prepbufr
   Total Surface Reports Scanned:       226898
   Drifting Buoys (564) DROPPED:          5005
   Reports (Ships/Etc) PRESERVED:       221893
   ---------------------------------------------------------
  Verification (Final Counts):
SFCSHP           256         53170        2193836      207.70
TOTAL           6119        960537       80436668

[Cycle 12z]
   [STDOUT] Filter: Inspecting Surface Categories for 564s...
   ---------------------------------------------------------
   CULL RESULTS FOR: /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr/20260501/gdas.t12z.prepbufr
   Total Surface Reports Scanned:       228421
   Drifting Buoys (564) DROPPED:          4990
   Reports (Ships/Etc) PRESERVED:       223431
   ---------------------------------------------------------
  Verification (Final Counts):
SFCSHP           250         51092        2108324      204.37
TOTAL           6513        989648       88440674

[Cycle 18z]
   [STDOUT] Filter: Inspecting Surface Categories for 564s...
   ---------------------------------------------------------
   CULL RESULTS FOR: /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr/20260501/gdas.t18z.prepbufr
   Total Surface Reports Scanned:       226731
   Drifting Buoys (564) DROPPED:          4968
   Reports (Ships/Etc) PRESERVED:       221763
   ---------------------------------------------------------
  Verification (Final Counts):
SFCSHP           249         51098        2108512      205.21
TOTAL           7763       1101686       95336918

------------------------------------------------------------
Filter Complete. All 564s removed, Ships preserved.
```
