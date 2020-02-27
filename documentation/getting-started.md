# Getting Started

These instructions should help you get started in using this tool.  We'll be walking through some provided examples with the hope that afterwards you can start to experiment and customize your radio to your liking more easily.

## Step 1: Download the example input CSV files
Download these 4 input CSV files:

* [Analog.csv](examples/Analog.csv)
* [Digital-Others.csv](examples/Digital-Others.csv)
* [Digital-Repeaters.csv](examples/Digital-Repeaters.csv)
* [TalkGroups.csv](examples/TalkGroups.csv)

Note, the above are meant to be examples; they're specific to the Pacific Northwest area and they're a bit out of date.   If you're in the PNW, check out the latest community-managed files on the [PNW Digital's Groups.io site](https://dmr.groups.io/g/PNW-CPS-Programming-Codeplugs/files/Codeplugs/Anytone/ACB/PNW-Community).

## Step 2: Upload them to the Tool
Go to the Anytone Config Builder tool, [here](./).  Then choose the 4 files you downloaded above and click "Upload"

## Step 3: Download the zip file
Assuming you uploaded all 4 of the example files, you should now be downloading a zip file.  Save that to your computer somewhere that you'll find it and extract the files.  You'll see that there are 4 files, you'll use those in the next step.

## Step 4: Prepare the CPS software
If you haven't installed the CPS software, you'll need to do that before you continue.

Run the CPS software.  Before we can import the our config files, we need to change a few things:

* In the Tools > Mode menu, check the "channel names are not unique" box.   This config creates channels with identical names and the CPS software doesn't allow that unless this box is checked
* On the left side, under the "Digital" tab, go into the Radio ID, make sure your DMR ID # is configured and the name is "DMR ID" (no quotes).  The config create channels with a DMR ID of "DMR ID", and this has to match.  You can change it later.

## Step 5: Import the CSV files
In the Tools > Import menu, click the buttons on the left to load the Channels, Zones, Scanlists, and Talkgroups file that you extracted from the zip file above.  Then hit Import.  The CPS software will take a moment to read these files, but you shouldn't get any errors (if you do, please let me know).

## Step 6: Enjoy
Write it to your radio.  You're done.


# Customizing
The example files that you downloaded in Step 1 produce an output that's nearly identical to the PNW Digital codeplug (the channel names are different - they're more systematic in this one - and the scanlist layout is different), but effectively the same thing.  If that's what you want, then great.  But, if you're like me, you want to tweak some thing.

For example, I don't have a hotspot and there's a few hotspots listed in the Digital-Repeaters file; I removed them.  In fact, there's a bunch of repeaters for places I'm not likely to ever go, so I removed those too.  I also added the PSRG DMR repeater in mine as well as some extra analog repeaters.  The point is, now that you've seen how to upload files, download the zip and import them, you can start customizing to your hearts content.  Let's talk about how to do that.

## Example: Adding a repeater
Let's say you want to add the PSRG DMR Repeater, here's how you do that.  The details for this repeater can be found on the PSRG site: [https://web.psrg.org/new-psrg-dmr-repeater-operational/](https://web.psrg.org/new-psrg-dmr-repeater-operational/).  The details that you are going to need are the RX and TX frequencies and the color code as well as the talkgroups that are carried on the repeater and their corresponding timeslots.  All of that information is on the PSRG DMR page above; so you're good to go.

To do this, open the Digital-Repeater.csv file; it should load in Excel (or a similar spreadsheet program).  Add a row - I've chosen to keep mine in alpabetical order because it's easier for me to manage these CSV files, but you can put yours at the bottom if that's easier for you.  Then, start typing:

* **Zone Name:** Seattle/PSRG
* **Comment**: anything you want, this comment only lives in this CSV for your own reference... it's ignored by the Config Builder tool
* **Power**: Must be one of "Low", "Mid", "High", or "Turbo"
* **RX Freq**: 440.775
* **TX Freq**: 445.775
* **Color Code**: 2

Now, this example is extra intersting as the PSRG Repeater has 2 talkgroups "Seattle 1" and "Seattle 2" that aren't carried on the other PNW Digital repeaters, so they're not listed in these files.  For the moment, we're going to skip those talkgroups, in the next example, I'll show you how to add them.

Ok, at this point, you basically just need to "check the boxes" for the talkgroups that are on this repeater (for the most part).  Everthing to the right of the "Color Code" column is a talk group that's configured (or not) on the repeater.  You can enter "-" if it's not supported or "1" or "2" to indicate timeslot 1 or 2, respectively.

I'd recommend filling in the entire row with "-", and then going back to enter "1" for the timeslot 1 talkgroups ("Wash 1", "Local 1",  etc) and "2" for the timeslot 2 talkgroups ("Wash 2", "Local 2", etc).  The PSRG DMR page provides a nice organized list.

Once that's done, and you've double checked that you've got a "-" in all the other talkgroups that aren't on these repeaters, save the file.  You could import it back into the Anytone Config Builder tool and repeat the rest of the steps above.

## Example: Adding a talkgroup
Let's say that you want to add some new talk groups.  Using the example above, you wan to add "Seattle 1" and "Seattle 2".  To do that, first go into the Talkgroups.csv (the input csv... not to be confused with the output CSV that was in the zip file).  This file is very simple: talkgroup name in the first column, talk group ID in the second column.  Add a row for "Seattle 1" with "803153" as the talk group and another row with "Seattle 2" and "813153".  Save that.

Next, go back into you the Digital-Repeaters.CSV and add two new columns (either at the end, or try to keep them alphabetized for your own sanity (the tool doesn't care)).  The header for these two columns should be "Seattle 1" and "Seattle 2".  Fill in a "-" for all the repeaters that don't carry these talk groups and a "1" or "2" as you did above to add it to the repeaters that do carry it

## Other exercises: Analog channels
The Analog.csv file lists the analog channels.  Edit to your hearts content; these fields should be fairly self-explanitory (but don't histate to ask).  The "TX Prohibit" field can be either "On" (in which case you can't PTT) or "Off"; this can be useful if you want to program things like NWS Weather stations that should be receive only.
