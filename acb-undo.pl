#!/usr/bin/perl


use strict;
use Text::CSV;

my $csv = Text::CSV_XS->new({binary => 1, auto_diag => 1, always_quote => 1, eol => "\r\n"});

open (my $file_analog, ">output/analog.csv") or die ("Couldn't open analog.csv for output");
open (my $file_digital_others, ">output/digital-others.csv") or die ("Couldn't open digital-others.csv for output");
open (my $file_digital_repeaters, ">output/digital-repeaters.csv") or die ("Couldn't open digital-repeaters.csv for output");
open (my $file_talkgroups, ">output/talkgroups.csv") or die ("Couldn't open talkgroups.csv for output");

my %chan_to_zone;
my %zone_freqs;
open(my $fh, "zones.csv") or error("Couldn't open file 'zones.csv': $!\n");
#"No.","Zone Name","Zone Channel Member","Zone Channel Member RX Frequency","Zone Channel Member TX Frequency","A Channel","A Channel RX Frequency","A Channel TX Frequency","B Channel","B Channel RX Frequency","B Channel TX Frequency"
for(my $line_no = 0; my $row = $csv->getline($fh); $line_no++)
{
    next if($line_no == 0); #skip the header row

    my $zone_name = $row->[1];
    my @chan_names = split('\|', $row->[2]);
    my @rx_freqs   = split('\|', $row->[3]);
    my @tx_freqs   = split('\|', $row->[4]);


    for(my $i = 0; $i < scalar(@chan_names); $i++)
    {
        my $chan_name = $chan_names[$i];
        my $rx_freq   = $rx_freqs[$i];
        my $tx_freq   = $tx_freqs[$i];

        my $key = "$chan_name,$rx_freq,$tx_freq";

        push @{$chan_to_zone{$key}}, $zone_name;

        push @{$zone_freqs{$zone_name}->{"$rx_freq,$tx_freq"}}, $chan_name;
    }

}
close($fh) or die("couldn't close 'zones.csv': $!\n");

my %digital_repeater_zones_freqs;
my %digital_others_zone_freqs;
foreach my $zone_name (keys %zone_freqs)
{
    foreach my $rx_tx_freqs (keys %{$zone_freqs{$zone_name}})
    {
        my $channel_count = scalar @{$zone_freqs{$zone_name}->{$rx_tx_freqs}};
        my $zone_freq     = "$zone_name,$rx_tx_freqs";

        if ($channel_count > 5) # totally arbitrary
        {
            $digital_repeater_zones_freqs{$zone_freq} = $channel_count;
        }
        else
        {
            $digital_others_zone_freqs{$zone_freq} = $channel_count;
        }
    }
}



my %talkgroups;
open (my $fh, "talkgroups.csv") or error("couldn't open talkgroups.csv: $!\n");
#"No.","Radio ID","Name","Call Type","Call Alert"
for (my $line_no = 0; my $row = $csv->getline($fh); $line_no++)
{
    next if ($line_no == 0); #skip the header row

    $talkgroups{$row->[1]} = $row->[2];

    print $file_talkgroups $row->[2] . "," . $row->[1] . "\n";
}


print $file_analog "Zone,Channel Name,Bandwidth,Power,RX Freq,TX Freq,CTCSS Decode,CTCSS Encode,TX Prohibit\n";
print $file_digital_others "Zone,Channel Name,Power,RX Freq,TX Freq,Color Code,Talk Group,TimeSlot,Call Type,TX Permit\n";

my @analog_channels;
my @digital_others_channels;
my %digital_repeater_color_code;
my %digital_repeater_power;
my %digital_repeater_all_tgs;
my %digital_repeater_tgs;
open(my $fh, "channels.csv") or error("couldn't open channes.csv: $!\n");
#"No.","Channel Name","Receive Frequency","Transmit Frequency","Channel Type","Transmit Power","Band Width","CTCSS/DCS Decode","CTCSS/DCS Encode","Contact","Contact Call Type","Contact TG/DMR ID","Radio ID","Busy Lock/TX Permit","Squelch Mode","Optional Signal","DTMF ID","2Tone ID","5Tone ID","PTT ID","Color Code","Slot","Scan List","Receive Group List","TX Prohibit","Reverse","Simplex TDMA","TDMA Adaptive","Encryption Type","Digital Encryption","Call Confirmation","Talk Around","Work Alone","Custom CTCSS","2TONE Decode","Ranging","Through Mode","Digi APRS RX","Analog APRS PTT Mode","Digital APRS PTT Mode","APRS Report Type","Digital APRS Report Channel","Correct Frequency[Hz]","SMS Confirmation","Exclude channel from roaming"
my $col_nums;
for(my $line_no = 0; my $row = $csv->getline($fh); $line_no++)
{
    if($line_no == 0)
    {
        $col_nums = row2cols($row);
        next;
    }

    my $chan_name       = $row->[$col_nums->{"Channel Name"}];
    my $chan_rx_freq    = $row->[$col_nums->{"Receive Frequency"}];
    my $chan_tx_freq    = $row->[$col_nums->{"Transmit Frequency"}];
    my $chan_type       = $row->[$col_nums->{"Channel Type"}];
    my $chan_power      = $row->[$col_nums->{"Transmit Power"}];
    my $chan_bw         = $row->[$col_nums->{"Band Width"}];
    my $chan_rx_tone    = $row->[$col_nums->{"CTCSS/DCS Decode"}];
    my $chan_tx_tone    = $row->[$col_nums->{"CTCSS/DCS Encode"}];
    my $chan_contact    = $row->[$col_nums->{"Contact"}];
    my $chan_call_type  = $row->[$col_nums->{"Contact Call Type"}];
    my $chan_tx_permit  = $row->[$col_nums->{"Busy Lock/TX Permit"}];
    my $chan_squelch    = $row->[$col_nums->{"Squelch Mode"}];
    my $chan_color_code = $row->[$col_nums->{"Color Code"}];
    my $chan_timeslot   = $row->[$col_nums->{"Slot"}];
    my $chan_tx_prohib  = $row->[$col_nums->{"TX Prohibit"}];

    my $key = "$chan_name,$chan_rx_freq,$chan_tx_freq";
    my $repeat = 0;
    foreach my $zone_name (@{$chan_to_zone{$key}})
    {

        # We should probably compare all the other fields in the channel vs the fields that ACB auto-populates to alert the user

        if ($chan_type eq "A-Analog")
        {
            my $output_chan_name = chan_name_iterate($chan_name, $repeat, $zone_name, $key);
            push @analog_channels, "$zone_name,$output_chan_name,$chan_bw,$chan_power,$chan_rx_freq,$chan_tx_freq,$chan_rx_tone,$chan_tx_tone,$chan_tx_prohib";
            #print $file_analog "$zone_name,$output_chan_name,$chan_bw,$chan_power,$chan_rx_freq,$chan_tx_freq,$chan_rx_tone,$chan_tx_tone,$chan_tx_prohib\n";
        }
        else #Digital
        {
            my $talkgroup = $chan_contact;

            my $zone_freq = "$zone_name,$chan_rx_freq,$chan_tx_freq";
            if ($digital_repeater_zones_freqs{$zone_freq} > 0)
            {
                if(defined($digital_repeater_color_code{$zone_name}) && $digital_repeater_color_code{$zone_name} != $chan_color_code)
                {
                    error("Channel '$chan_name' has color code '$chan_color_code', which doesn't match other channels on repeater '$zone_name'");
                }

                $digital_repeater_color_code{$zone_name} = $chan_color_code;
                $digital_repeater_power{$zone_name} = $chan_power; #this means last one wins, which may be a bad idea. 
                $digital_repeater_all_tgs{$talkgroup}++;
                $digital_repeater_tgs{$zone_name}->{$talkgroup} = $chan_timeslot; #TODO: handle private call stuff.
                
            }
            else
            {
                my $output_chan_name = chan_name_iterate($chan_name, $repeat, $zone_name, $key);
                push @digital_others_channels, "$zone_name,$output_chan_name,$chan_power,$chan_rx_freq,$chan_tx_freq,$chan_color_code,$talkgroup,$chan_timeslot,$chan_call_type,$chan_tx_permit";
                #print "$zone_name,$output_chan_name,$chan_power,$chan_rx_freq,$chan_tx_freq,$chan_color_code,$talkgroup,$chan_timeslot,$chan_call_type,$chan_tx_permit\n";
            }
        }

        $repeat++;
    }    
}


foreach my $line (sort @analog_channels)
{
    print $file_analog $line . "\n";
}

foreach my $line (sort @digital_others_channels)
{
    print $file_digital_others $line . "\n";
}

print $file_digital_repeaters "Zone Name,Comment,Power,RX Freq,TX Freq,Color Code," . join(",", sort keys %digital_repeater_all_tgs) . "\n";
foreach my $zone_freq (sort keys %digital_repeater_zones_freqs)
{
    my ($zone_name, $rx_freq, $tx_freq) = split(",", $zone_freq);
    my $power = $digital_repeater_power{$zone_name};
    my $color = $digital_repeater_color_code{$zone_name};
    print $file_digital_repeaters "$zone_name,,$power,$rx_freq,$tx_freq,$color,";

    my @tgs;
    foreach my $talkgroup (sort keys %digital_repeater_all_tgs)
    {
        my $tg = "-";
        if (length($digital_repeater_tgs{$zone_name}->{$talkgroup}) > 0)
        {
            $tg = $digital_repeater_tgs{$zone_name}->{$talkgroup};
        }

        push @tgs, $tg;
    }

    print $file_digital_repeaters join(",", @tgs) . "\n";

}

sub chan_name_iterate
{
    my ($chan_name, $repeat, $zone, $key) = @_;

    # I don't think any of this is needed... so...
    return $chan_name;

    # remove the above line to get this section back
    my $orig_name = $chan_name;

    return $chan_name if($repeat == 0);

    $chan_name .= chr($repeat - 1 + ord('a'));
    if (length($chan_name) > 16)
    {
        $chan_name =~ s/[aeiou]//gi; # drop the vowels... which is shitty
        $chan_name .= chr($repeat - 1 + ord('a'));
    }

    if (length($chan_name) > 16)
    {
        error("Duplicate channel '$orig_name' can't be shortened =(");
    }

    print "INFO: Channel '$orig_name' is referenced in multiple zones.  ACB uses a 1:1 channel-zone mapping, so this channel will be duplicated. It will be called '$chan_name' in zone '$zone' ($key)\n";

    return $chan_name;
}

sub error
{
    my ($error) = @_;

    print "ERROR: $error\n";
    exit -1;
}


sub row2cols
{
    my ($row) = @_;

    my %col_nums;
    for(my $i = 0; $i < scalar(@{$row}); $i++)
    {
        $col_nums{$row->[$i]} = $i;
    }

    return \%col_nums;
}
