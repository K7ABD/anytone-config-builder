# Advanced Options

Please note that these are <i>options</i>.  The defaults will work fine for most people.  So, if you don't feel like reading this stuff, or if this doesn't make sense, you can safely ignore it.

## Zone/Talkgroup Sort Order
This setting controls how your zones are organized. 

**Alphabetize them for me** - This is the default option; the tool will sort your zones alphabetically.  Within the Digital Repeater zones (1 zone per repeater), the channels (1 per talk group) will be sorted alphabetically by talk group name.  Within the Analog/Digital-Others zones, the channels will be sorted alphabetically as well.

**Use my sorting, DMR Repeaters as the first zone** - this lets you control the sorting.  For the Digital Repeater zones (1 zone per repeater), you can control the order of the zones by simply ordering the rows in the Digital-Repeaters.csv to your liking.  For the Digital Repeater channels (1 per talk group), you can control the ordering of those by sorting your TalkGroups.csv file as you see fit.  The Analog and Digital-Others channels will follow the order that you specied in those files and will follow the digital repeaters.

**Use my sorting, Analog channels as first zone** - this is the same as the above, but the first zone will be the Analog/Digital-Others zones, the DMR repeaters will follow behind using your ordering, as described above.

## TX Permit setting for Hotspots
Some hotspot owners would prefer a TX Permit setting of "Always" when they're using their hotspot.  The default is "Same Color Code".

**Same Color Code** - This is the default option; all Digital Repeater channels have the TX Permit setting of "Same Color Code"

**Always** - For every Digital Repeater which has the same TX and RX Frequency, the TX Permit setting will be set to "Always".

## Digital Repeater Nicknames
Some people prefer to have their channel names indicate which repeater they're using.  This feature allows you to prepend or append each channel name from the Digital Repeaters file with a prefix or suffix (at your choosing).

To use this, add a nickname to each of the zones in the Digital Repeates file, like so:  "Full Zone Name;FZN" or "Olympia/Cap Pk.;OLY".  If you select eithe "prefix" or "suffix" for Digital Repeater Nicknames, the tool will create channel names that include your nickname.

You can choose "prefix (if needed)" or "suffix (if needed)" and the prefix/suffix will be used only if the channel name length exceed 16 characters.   If you choose "prefix (forced)" or "suffix (forced)", the prefix/suffix will be used even if the longer name would have fit.

Additionally, because some talkgroups have long names and the Anytone radios support only 16 character channel names, you can also provide a shortened name for your talkgroups in a similar manner.  For example, "Worldwide English" might become "Worldwide English;WW English" leaving enough room for your prefix/suffix.
