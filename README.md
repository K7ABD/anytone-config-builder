# Introduction

Anytone Config Builder is a script which creates channels, zones, scanlist and talkgroup CSV files that you can import into the Anytone CPS.  The goal of this software is to simplify the creating of codeplugs that are consistent and correct; hand-managed channel lists are just too easy to mess up.

This program takes in 4 files as inputs (described below), examples are provided in the input-csv directory.  The example input CSV files come directly from the PNW Digital's code plug (as of 2019-04-29) - in fact, if you run this script on those input files, you'll get a set of channels and zones that are identical to what comes in that code plug.

So, why bother?   Well, code plug files aren't transparent.  It's difficult to track the differences between different versions of them; it's difficult to audit/bug-check; it's difficult to manipulate/prune; it's difficult to add new repeaters ;etc.  Basically: code plug files kinda suck from a maintainability perspective.

The goal of this package is to bring a bit of sanity to codeplug building.

# Input files
There are 4 files that you'll need.  These are ASCII CSV files (you should be able to open these in MS Excel or similar spreadsheet program).  Here's a description of these files:

### Analog.csv
This file is a list of analog channels that you'd like in the repeater.  If you've used CHIRP, this should be fairly familiar; it's all the basic stuff that you need for analog channels:   RX/TX Frequencies, CTCSS tones, Power level, Bandwidth (for FM or NFM).  It also include a "TX Prohibit" field which is useful if you want to include things like NWS Weather channels that you want to be able to listen to, but not accidently transmit onto.

Channel Names can be up to 16 characters.  You can group your channels into different zones which helps keep them organized.  The example input file has a few such zones: VHF repeaters, UHF repeaters, simplex, etc.

##### Details
- **Zone** - Up to 16 characters
- **Channel Name** - Up to 16 characters
- **Bandwidth** - "25K" for FM or "12.5K" for NFM
- **Power** - "Turbo", "High", "Mid", "Low"
- **RX/TX Freq** - the frequency, in MHz
- **CTCSS Decode/Encode** - the CTCSS code, in Hz or "Off"
- **TX Prohibit** - "Off" or "On"

### Digital-Others.csv
This is a similar file to the Analog file above, but these are one-off DMR channels.  In the example file, it has the DMR Simplex channels as well as some Brandmeister digital APRS stations.
- **Zone** - Up to 16 characters
- **Channel Name** - Up to 16 characters
- **Power** - "Turbo", "High", "Mid", "Low"
- **RX/TX Freq** - the frequency, in MHz
- **Color Code** - the DMR Color Code
- **Talk Group** - the name of the talk group
- **Time Slot** - the DMR Timeslot (either 1 or 2)
- **Call Type** - either "Call Group" or "Private Call"
- **TX Permit** - the DMR TX Permit setting.  You probably want "Always" for Simplex and "Same Color Code" for everything else.


## Digital-Repeaters.csv
This is kinda where a lot of the awesome happens.  Unlike the files above, this is a matrix of repeater frequencies and the talkgroups that are supported on that talkgroup.  The first 5 columns are specific to each repeater:

- **Zone Name** - Up to 16 characters
- **Comment** - This is just for your notes, it's totally ignored by the program
- **Power** - "Turbo", "High", "Mid", "Low"
- **RX/TX Freq** - the frequency, in MHz
- **Color Code** - the DMR Color Code of the repeater

The rest of the columns headers are the names of talk groups.  The value in each of those columns it the timeslot, either 1, 2 or "-" (where "-") means it's not configured on the talkgroup.

What this means for you is that adding a repeater is as simple as adding another row to this file, marking off which talkgroups are supported on which timeslot and running the script.


## Talkgroups.csv
A simple file listing talk group names (these must match what's in the DMR files above) and their talk group IDs. 

# Output
This produces 4 files as outputs that can be directly imported into the Anytone CPS:
- channels.csv
- scanlists.csv
- talkgroups.csv
- zones.csv

What you'll wind up with is the following:
   - A Zone for every zone you specified in the Analog and Digital-Others files
   - A Zone for every repeater in the Digital-Repeaters file
   - A scanlist for every every zone in the Analog and Digital-Others files
   - A scanlist for every *talkgroup* in the Digital-Repeaters file.  This means that if you're listening to a talkgroup, say "Wash 1" and hit scan, you'll scan all of the other repeaters that have "Wash 1" as a configured talk group
   - A channel for every line in the Analog and Digital-Others files
   - A channel for every repeater on each talkgroup that's configured (that matrix described above gets multiplied out).  These channels are named for the talkgroup


# CPS Stuff
#### Duplicate Channel Names
This creates channels with duplicate names.  Before importing these files, you need to allow the CPS software to use duplicate names by going to Tools > Mode and checking the box for "Contact name is not unique / Channel name is not unique"

#### Radio ID
This spits out a file with a Radio Id of "DMR ID".  Before you import these files, you need to go into the "Digital" tab, and in the "Radio ID List" insure that your Radio ID (your DMR ID) is set and that the name is "DMR ID".  You can change this later if you prefer something else.

#### Contact List
You're on your own for contacts.  I pulled mine in by starting with the PNWDigital code plug (which has the contacts), then importing the files created by this tool


# Usage
    ./anytone-config-builder.pl --analog-csv=input-csv/Analog.csv --digital-others-csv=input-csv/Digital-Others.csv --digital-repeaters-csv=input-csv/Digital-Repeaters.csv --talkgroups-csv=input-csv/TalkGroups.csv --output-directory=output/

It'll dump the output csv's into the output directory.  You should get fairly readable error messages if you screw something up.



