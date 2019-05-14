#!/usr/bin/perl


use strict;
use Text::CSV;

use constant {
    CHAN_NUM            => 0,
    CHAN_NAME           => 1,
    CHAN_RX_FREQ        => 2,
    CHAN_TX_FREQ        => 3,
    CHAN_MODE           => 4,
    CHAN_POWER          => 5,
    CHAN_BANDWIDTH      => 6,
    CHAN_CTCSS_DEC      => 7,
    CHAN_CTCSS_ENC      => 8,
    CHAN_CONTACT        => 9,
    CHAN_CALL_TYPE      => 10,
    CHAN_RADIO_ID       => 11,
    CHAN_TX_PERMIT      => 12,
    CHAN_SQUELCH        => 13,
    CHAN_OPT_SIG        => 14,
    CHAN_DTMF_ID        => 15,
    CHAN_2TONE_ID       => 16,
    CHAN_COLOR_CODE     => 19,
    CHAN_SLOT           => 20,
    CHAN_SCANLIST_NAME  => 21,
};

use constant {
    VAL_DIGITAL     => 'D-Digital',
    VAL_ANALOG      => 'A-Analog',
};

use constant {
    COLOR_OK        => "#88FF88",
    COLOR_WARN      => "#FFFF88",
    COLOR_BAD       => "#FF8888",
};

my $csv = Text::CSV_XS->new({binary => 1, auto_diag => 1, quote_char=>'"'});

main();
exit 0;


sub main
{
    my @data;
    my @header;

    if (scalar (@ARGV) == 0)
    {
        usage();
        exit(-1);
    }

    html_start();

    my $filename = $ARGV[0];

    # walk through the file and build a giant 2D array of the rows and columns in this file.
    open(my $fh, $filename) or die("Couldn't open file '$filename': $!\n");
    for(my $line_no = 0; my $row = $csv->getline($fh); $line_no++)
    { 
        if ($line_no == 0)
        {
            @header = @$row;
        }
        else
        {
            push @data, $row;
        }
    }
    close ($fh) or die("Couldn't close file '$filename': $!\n");

    report_digital_repeater_freq_pairs(\@data);
    report_digital_repeater_color_codes(\@data);
    report_digital_repeater_talk_groups_slots(\@data);
    report_digital_repeater_arbitrary_fields(\@data); 
    html_end();
}


sub report_digital_repeater_freq_pairs
{
    my ($data_ref) =@_;

    my @key_array = (0);
    analyze_key_value_pairs($data_ref, \@key_array, \&repeater_name, \&repeater_pair, \&digital_repeater_filter,
            \&chan_num_and_name, "Scan List Name", "Frequency Pair (RX / TX)", 
            join_freq_pairs("???.?????","???.?????"),
            "Digital Repeater Frequency Pair Consistency Report");
}

sub report_digital_repeater_color_codes
{
    my ($data_ref) = @_;

    my @key_array = (0);
    analyze_key_value_pairs($data_ref, \@key_array, \&repeater_name, \&color_code, \&digital_repeater_filter,
            \&chan_num_and_name, "Scan List Name", "Color Code",  "??",
            "Digital Repeater Color Code Consistency Report");
}

sub report_digital_repeater_talk_groups_slots
{
    my ($data_ref) = @_;

    my @key_array = (0);
    analyze_key_value_pairs($data_ref, \@key_array, \&talk_group, \&time_slot, \&digital_repeater_filter,
            \&chan_num_and_name, "Talk Group", "Time Slot",  "??",
            "Digital Repeater Talk Group / Time Slot Consistency Report");
}

sub report_digital_repeater_arbitrary_fields
{
    my ($data_ref) = @_;

    my @key_array = (5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 23, 24, 25, 26, 27, 28, 29, 30, 31, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43);
    analyze_key_value_pairs($data_ref, \@key_array, \&arbitrary_field_key, \&arbitrary_field_value,
            \&digital_repeater_filter, \&chan_num_and_name, "Field", "Value", "??",
            "Digital Repeater Other Field Consistency Report");
}

sub color_code
{
    my ($id, $chan) = @_;
    return $chan->[CHAN_COLOR_CODE];
}

sub talk_group
{
    my ($id, $chan) = @_;
    return $chan->[CHAN_CONTACT];
}

sub time_slot
{
    my ($id, $chan) = @_;
    return $chan->[CHAN_SLOT];
}

sub chan_num_and_name
{
    my ($id, $chan) = @_;
    return "Channel " . $chan->[CHAN_NUM] . " - \"" . $chan->[CHAN_NAME] . "\"";
}

sub repeater_pair
{
    my ($id, $chan) = @_;
    return join_freq_pairs($chan->[CHAN_RX_FREQ], $chan->[CHAN_TX_FREQ]);
}

sub repeater_name
{
    my ($id, $chan) = @_;
    return $chan->[CHAN_SCANLIST_NAME];
}

sub arbitrary_field_value
{
    my ($id, $chan) = @_;
    return $chan->[$id];
}

sub arbitrary_field_key
{
    my ($id, $chan) = @_;
    return anytone_channels_csv_column_name($id);
}

sub digital_repeater_filter
{
    my ($chan) = @_;

    return $chan->[CHAN_MODE] eq VAL_DIGITAL && $chan->[CHAN_RX_FREQ] ne $chan->[CHAN_TX_FREQ];
}

sub analyze_key_value_pairs
{
    my ($data_ref, $key_array, $key_func, $value_func, $filter_func, $chan_name_func,
                   $key_name, $value_name, 
                   $unknown_value, $title) = @_;

    html_section($title);

    my %data;
    foreach my $chan (@{$data_ref})
    {
        if ($filter_func->($chan))
        {
            foreach my $key_id (@{$key_array})
            {
                my $value = $value_func->($key_id, $chan);
                my $key   = $key_func->($key_id, $chan);
                push @{$data{$key}->{$value}}, $chan_name_func->($key_id, $chan);
            }
        }
 
    }

    print "<table>";
    print "<tr><th>$key_name</th><th>Count</th><th>$value_name</th></tr>";


    foreach my $key (sort keys %data)
    {

        my $sum = 0;
        my $max_count = 0;
        my $max_value = '';
        my $distinct_values = 0;
        foreach my $value (sort keys %{$data{$key}})
        {
            my $count = scalar @{$data{$key}->{$value}};
            if ($count > $max_count)
            {
                $max_value  = $value;
                $max_count = $count;
            }
            $sum += $count;
            $distinct_values++;
        }

        my $likely_value;
        my $likely_count = $max_count;
        my $bg_color;

        if ($distinct_values == 1)
        {
            $bg_color = COLOR_OK;
            $likely_value = $max_value;
        } 
        elsif ($max_count / $sum > 0.70)  # if 70% of the channels are using this pair it's the dominate pair
        {
            $bg_color = COLOR_BAD;
            $likely_value = $max_value;
        }
        else
        {
            $bg_color = COLOR_WARN;
            $likely_value = $unknown_value;
            $likely_count = "??";
        }

        print "<tr bgcolor='$bg_color'><td><b>$key</b></td><td>$likely_count</td><td><b>$likely_value</b></td></tr>";
       
        # OK... so we found more than one value for this key... let's highlight the odd-balls 
        if ($distinct_values != 1) 
        {
            foreach my $value (sort keys %{$data{$key}})
            {
                next if ($value eq $likely_value);  # these are the good ones, no need to print them

                foreach my $chan_desc (@{$data{$key}->{$value}})
                {
                    print "<tr bgcolor='$bg_color'><td>&nbsp; &nbsp; &nbsp; $chan_desc</td>";
                    print "<td></td>";
                    print "<td>$value</td></tr>";
                }
            }
        }
    }

    print "</table>";

}



sub usage
{
    print "$0 <channels file CSV>\n";
}


sub join_freq_pairs
{
    my ($rx, $tx) = @_;
    return "$rx &nbsp; $tx";
}

sub split_freq_pairs
{
    my ($pair) = @_;

    my ($rx, $tx);
    if ($pair =~ /^(.*?)\s+(.*)/)
    {
        $rx = $1;
        $tx = $2;
    }
    return ($rx, $tx);
}

sub html_start
{
    print <<'HTML_START';
<html><head><title>Andrew's Booger Detector</title>
<style type="text/css">
table, th, td {
    border: 1px solid black;
    border-collapse: collapse;
    font-family: monospace;
    text-align: left;
    padding: 2px;
}
</style>
</head><body>
<h1>Andrew's Booger Detector</h1>
HTML_START
}

sub html_section
{
    my $section = shift @_;
    print "<h2>$section<h2>";
}

sub html_end
{
    print "</body></html>";
}

sub anytone_channels_csv_column_name
{
    my $col_num = shift @_;

    my %cols = (
        0 => "No.",
        1 => "Channel Name",
        2 => "Receive Frequency",
        3 => "Transmit Frequency",
        4 => "Channel Type",
        5 => "Transmit Power",
        6 => "Band Width",
        7 => "CTCSS/DCS Decode",
        8 => "CTCSS/DCS Encode",
        9 => "Contact",
        10 => "Contact Call Type",
        11 => "Radio ID",
        12 => "Busy Lock/TX Permit",
        13 => "Squelch Mode",
        14 => "Optional Signal",
        15 => "DTMF ID",
        16 => "2Tone ID",
        17 => "5Tone ID",
        18 => "PTT ID",
        19 => "Color Code",
        20 => "Slot",
        21 => "Scan List",
        22 => "Receive Group List",
        23 => "TX Prohibit",
        24 => "Reverse",
        25 => "Simplex TDMA",
        26 => "TDMA Adaptive",
        27 => "Encryption Type",
        28 => "Digital Encryption",
        29 => "Call Confirmation",
        30 => "Talk Around",
        31 => "Work Alone",
        32 => "Custom CTCSS",
        33 => "2TONE Decode",
        34 => "Ranging",
        35 => "Through Mode",
        36 => "Digi APRS RX",
        37 => "Analog APRS PTT Mode",
        38 => "Digital APRS PTT Mode",
        39 => "APRS Report Type",
        40 => "Digital APRS Report Channel",
        41 => "Correct Frequency[Hz]",
        42 => "SMS Confirmation",
        43 => "Exclude channel from roaming",
    );

    my $result = "Unknown Column '$col_num'";
    if (length($cols{$col_num}) > 0)
    {
        $result = $cols{$col_num};
    }

    return $result;
}
