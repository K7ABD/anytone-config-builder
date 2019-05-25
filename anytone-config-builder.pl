#!/usr/bin/perl


use strict;
use Text::CSV;
use Scalar::Util qw(looks_like_number);
use Getopt::Long;


use constant {
    # There are other fields, but these are the ones we care about
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
    CHAN_TX_PERMIT      => 12,
    CHAN_COLOR_CODE     => 19,
    CHAN_TIME_SLOT      => 20,
    CHAN_SCANLIST_NAME  => 21,
    CHAN_TX_PROHIBIT    => 23,
};


use constant {
    VAL_DIGITAL          => 'D-Digital',
    VAL_ANALOG           => 'A-Analog',
    VAL_NO_TIME_SLOT     => "-", # this is from the input CSV, not a Anytone-ism
    VAL_TX_PERMIT_SAME   => "Same Color Code",
    VAL_TX_PERMIT_ALWAYS => "Always",
};


my $global_sort_mode = "alpha";
my $global_hotspot_tx_permit = "same-color-code";

my $global_channel_number = 1; 
my %channel_csv_field_name;
my %channel_csv_default_value;
my %talkgroup_mapping;
my %zone_config;
my %zone_order;
my $zone_order_default = 9999; # this impacts where the analog and digital-others go.
my %scanlist_config;
my %talkgroup_config;
my %talkgroup_order;
my $csv;

main();
exit 0;



sub main
{
    my ($analog_filename, $digital_others_filename, $digital_repeaters_filename, $talkgroups_filename,
        $config_directory, $output_directory) = handle_command_line_args();

    $csv = Text::CSV_XS->new({binary => 1, auto_diag => 1, always_quote => 1, eol => "\r\n"});

    read_talkgroups($talkgroups_filename);
    read_channel_csv_default( "$config_directory/channel-defaults.csv");

    open (my $fh, '>', "$output_directory/channels.csv") or die("Couldn't open channels.csv for writing\n");
    print_channel_header($fh);
    process_dmr_others_file(  $fh, $digital_others_filename);
    process_dmr_repeater_file($fh, $digital_repeaters_filename);
    process_analog_file(      $fh, $analog_filename);
    close ($fh);

    write_zone_file("$output_directory/zones.csv");
    write_scanlist_file("$output_directory/scanlists.csv");
    write_talkgroup_file("$output_directory/talkgroups.csv");

}


################################################################################
################################################################################
################################################################################
##########   CSV OUTPUT ROUTINES
################################################################################
################################################################################
################################################################################

#####
##### Zone file output #####
#####
sub write_zone_file
{
    my ($filename) = @_;

    my @headers = ("No.", "Zone Name", 
                  "Zone Channel Member", "Zone Channel Member RX Frequency", "Zone Channel Member TX Frequency", 
                     "A Channel",                  "A Channel RX Frequency",           "A Channel TX Frequency",
                     "B Channel",                  "B Channel RX Frequency",           "B Channel TX Frequency");

    generate_csv_file($filename, \@headers, \%zone_config, \&zone_row_builder, \&zone_sort);

}

sub write_scanlist_file
{
    my ($filename) = @_;

    my @headers = ("No.", "Scan List Name", 
                   "Scan Channel Member", "Scan Channel Member RX Frequency", "Scan Channel Member TX Frequency", 
                   "Scan Mode", "Priority Channel Select", 
                   "Priority Channel 1", "Priority Channel 1 RX Frequency", "Priority Channel 1 TX Frequency",
                   "Priority Channel 2", "Priority Channel 2 RX Frequency", "Priority Channel 2 TX Frequency",
                   "Revert Channel", "Look Back Time A[s]", "Look Back Time B[s]", "Dropout Delay Time[s]", 
                   "Dwell Time[s]");

    generate_csv_file($filename, \@headers, \%scanlist_config, \&scanlist_row_builder, \&case_insensitive_sort);
}


sub write_talkgroup_file
{
    my ($filename) = @_;

    my @headers = ("No.", "Radio ID", "Name", "Country", "Remarks", "Call Type", "Call Alert");

    generate_csv_file($filename, \@headers, \%talkgroup_config, \&talkgroup_row_builder, \&case_insensitive_sort);
}


sub zone_row_builder
{
    my ($zone_number, $zone_name, $zone_record) = @_;

    return generic_row_builder($zone_number, $zone_name, $zone_record, \&zone_row_details);
}


sub scanlist_row_builder
{
    my ($scan_number, $scan_name, $scan_record) = @_;

    return generic_row_builder($scan_number, $scan_name, $scan_record, \&scanlist_row_details);
}


sub talkgroup_row_builder
{
    my ($tg_number, $talkgroup_name, $junk) = @_;

    my @values;

    push @values, $tg_number;
    push @values, $talkgroup_mapping{$talkgroup_name};;
    push @values, $talkgroup_name;
    push @values, "";
    push @values, "";
    push @values, "Group Call";
    push @values, "None";

    return \@values;
}


sub generic_row_builder
{
    my ($row_number, $row_name, $row_record, $row_func) = @_;

    my @values;

    push @values, $row_number;
    push @values, $row_name;

    my @channels;
    my @rx_freqs;
    my @tx_freqs;
    foreach my $row_details (sort case_insensitive_sort @{$row_record})
    {
        my ($order, $chan_name, $rx_freq, $tx_freq) = split("\t", $row_details);
        $chan_name =~ s/\s+$//;   #TODO: This sort of trimming should live WAAAAY higher elsewhere
        push @channels, $chan_name;
        push @rx_freqs, $rx_freq;
        push @tx_freqs, $tx_freq;
    }        

    push @values, join("|", @channels);
    push @values, join("|", @rx_freqs);
    push @values, join("|", @tx_freqs);
    $row_func->(\@values, $channels[0], $rx_freqs[0], $tx_freqs[0]);
    return \@values;
}


sub zone_row_details
{
    my ($values_ref, $channel0, $rx0, $tx0) = @_;

    push @{$values_ref}, $channel0;
    push @{$values_ref}, $rx0;
    push @{$values_ref}, $tx0;
    push @{$values_ref}, $channel0;
    push @{$values_ref}, $rx0;
    push @{$values_ref}, $tx0;
}


sub scanlist_row_details
{
    my ($values_ref, $channel0, $rx0, $tx0) = @_;

    push @{$values_ref}, "Off";
    push @{$values_ref}, "Off";
    push @{$values_ref}, "";
    push @{$values_ref}, "";
    push @{$values_ref}, "Off";
    push @{$values_ref}, "";
    push @{$values_ref}, "";
    push @{$values_ref}, "Selected";
    push @{$values_ref}, "0.5";
    push @{$values_ref}, "0.5";
    push @{$values_ref}, "0.1";
    push @{$values_ref}, "0.1";
}


#####
#####  Generic CSV file writer given a hash of data
#####
sub generate_csv_file
{
    my ($filename, $headers, $data, $row_func, $sort_func) = @_;

    open(my $fh, ">$filename") or die("Couldn't open file '$filename': $!\n");

    $csv->print($fh, $headers);

    my $row_num = 1;
    foreach my $key (sort $sort_func keys %{$data})
    {
        my $value = $data->{$key};
        my $row = $row_func->($row_num, $key, $value);

        $csv->print($fh, $row);

        $row_num++;
    }

    close($fh) or die("Couldn't close file '$filename': $!\n");
}


sub print_channel_header
{
    my ($out_fh) = @_;

    my @output;
    foreach my $index (sort {$a <=> $b} keys %channel_csv_field_name)
    {
        push @output, $channel_csv_field_name{$index};
    } 

    $csv->print($out_fh, \@output);
}


##########
####  Sort Functions
##########
sub zone_sort
{
    my $a_i = $zone_order{$a};
    my $b_i = $zone_order{$b};

    # If we're in alphabetical mode or if the zone indexes are the same (which will be the case if we're in
    # non-alphabetical mode for the analog and digital-other channels).
    if ($global_sort_mode eq 'alpha' or $a_i == $b_i)
    {
        return lc($a) cmp lc($b);
    }
    else
    {
        return $a_i <=> $b_i
    }
}


sub case_insensitive_sort
{
    # no fancy scanning rules here
    return lc($a) cmp lc($b);
}



################################################################################
################################################################################
################################################################################
##########   CSV INPUT ROUTINES
################################################################################
################################################################################
################################################################################



#####
#  Analog CSV 
#####
sub process_analog_file
{
    my ($fh, $filename) = @_;

    my @header = ("Zone", "Channel Name", "Bandwidth", "Power", 
                  "RX Freq", "TX Freq", "CTCSS Decode", "CTCSS Encode",
                  "TX Prohibit");

    process_csv_file_with_header($fh, $filename, "Analog", \@header, \&analog_csv_field_extractor);
}

sub analog_csv_field_extractor
{
    my ($row) = @_;

    my %chan_config;
    $chan_config{+CHAN_SCANLIST_NAME}   = validate_zone(        $row->[0]);
    $chan_config{+CHAN_NAME}            = validate_name(        $row->[1]);
    $chan_config{+CHAN_BANDWIDTH}       = validate_bandwidth(   $row->[2]);
    $chan_config{+CHAN_POWER}           = validate_power(       $row->[3]);
    $chan_config{+CHAN_RX_FREQ}         = validate_freq(        $row->[4]);
    $chan_config{+CHAN_TX_FREQ}         = validate_freq(        $row->[5]);
    $chan_config{+CHAN_CTCSS_DEC}       = validate_ctcss(       $row->[6]);
    $chan_config{+CHAN_CTCSS_ENC}       = validate_ctcss(       $row->[7]);
    $chan_config{+CHAN_TX_PROHIBIT}     = validate_tx_prohibit( $row->[8]);
    $chan_config{+CHAN_MODE}            = VAL_ANALOG;

    return \%chan_config;
}


#####
## DMR Others CSV
#####
sub process_dmr_others_file
{
    my ($fh, $filename) = @_;

    my @header = ("Zone", "Channel Name", "Power", "RX Freq", "TX Freq", "Color Code", "Talk Group", "TimeSlot", 
                  "Call Type", "TX Permit");

    process_csv_file_with_header($fh, $filename, "Digital-Others", \@header, \&dmr_others_csv_field_extractor);
}

sub dmr_others_csv_field_extractor
{
    my ($row) = @_;

    my %chan_config;
    $chan_config{+CHAN_SCANLIST_NAME}   = validate_zone(        $row->[0]);
    $chan_config{+CHAN_NAME}            = validate_name(        $row->[1]);
    $chan_config{+CHAN_POWER}           = validate_power(       $row->[2]);
    $chan_config{+CHAN_RX_FREQ}         = validate_freq(        $row->[3]);
    $chan_config{+CHAN_TX_FREQ}         = validate_freq(        $row->[4]);
    $chan_config{+CHAN_COLOR_CODE}      = validate_color_code(  $row->[5]);
    $chan_config{+CHAN_CONTACT}         = validate_contact(     $row->[6]);
    $chan_config{+CHAN_TIME_SLOT}       = validate_timeslot(    $row->[7]);  
    $chan_config{+CHAN_CALL_TYPE}       = validate_call_type(   $row->[8]); 
    $chan_config{+CHAN_TX_PERMIT}       = validate_tx_permit(   $row->[9]); 
    $chan_config{+CHAN_MODE}            = VAL_DIGITAL;


    return \%chan_config;
}





#####
# DMR Repeater CSV
#####

sub process_dmr_repeater_file
{
    my ($fh, $filename) = @_;

    my @header = ("Zone Name", "Comment", "Power", "RX Freq", "TX Freq", "Color Code");

    process_csv_file_with_header($fh, $filename, "Digital-Repeater", \@header, \&dmr_repeater_csv_field_extractor, 
                                                                               \&dmr_repeater_csv_matrix_extractor);
}

sub dmr_repeater_csv_field_extractor
{
    my ($row) = @_;

    my %chan_config;
    $chan_config{+CHAN_SCANLIST_NAME}   = validate_zone(       $row->[0]);
                                                             # $row->[1] is a comment column
    $chan_config{+CHAN_POWER}           = validate_power(      $row->[2]);
    $chan_config{+CHAN_RX_FREQ}         = validate_freq(       $row->[3]);
    $chan_config{+CHAN_TX_FREQ}         = validate_freq(       $row->[4]);
    $chan_config{+CHAN_COLOR_CODE}      = validate_color_code( $row->[5]);
    $chan_config{+CHAN_MODE}            = VAL_DIGITAL;

    return \%chan_config;
}

sub dmr_repeater_csv_matrix_extractor
{
    my ($chan_config, $contact, $timeslot) = @_;
    
    my $do_multiply = 0;

    $timeslot = validate_timeslot($timeslot);
    if ($timeslot ne VAL_NO_TIME_SLOT)
    { 
        $chan_config->{+CHAN_CONTACT}   = validate_contact($contact);
        $chan_config->{+CHAN_TIME_SLOT} = validate_timeslot($timeslot);
        $chan_config->{+CHAN_NAME}      = validate_channel_name($contact);
        $do_multiply = 1;
    }

    return ($do_multiply, $chan_config);
}




#####
#####
## These two routines are basically the same... let's extract the common parts and make this generic
#####
#####
sub read_channel_csv_default
{
    my ($filename) = @_;

    open(my $fh, $filename) or die("Couldn't open file '$filename': $!\n");

    for(my $line_no = 0; my $row = $csv->getline($fh); $line_no++)
    {
        $channel_csv_field_name{   $row->[0]} = $row->[1];
        $channel_csv_default_value{$row->[0]} = $row->[2];
    }
   
    close($fh); 
}


sub read_talkgroups
{
    my ($filename) = @_;

    open(my $fh, $filename) or die("Couldn't open file '$filename': $!\n");

    my $index = 1;
    for(my $line_no = 0; my $row = $csv->getline($fh); $line_no++)
    {
        $talkgroup_mapping{$row->[0]} = $row->[1];
        $talkgroup_order{$row->[0]} = $index++;
    }
   
    close($fh); 
}




#####
#####
## This is where a lot of the magic happens... 
#####
#####

# This is where we read the input CSV files.  This is a fairly generic routine that is driven by it's arguments.
# Specifically, it takes a few function references to do the actual "hard work" of extracting the relevant fields
# into a "chan_config" hash which then gets passed into the "add_channel" routine at the end.
#
# This is made slightly more intersting/complicated by the fact that our repeaters input has a few columns that are
# the same for every channel (frequencies and such), but then has a big matrix of talk groups that are available on
# the repeater.  So, this routine ALSO does the "matrix multiplication" (probably a poor word choice) by extracting
# the talk group names and then multiplying out the row into a channel for each talkgroup that's on the repeater.
#
sub process_csv_file_with_header
{
    my ($out_fh, $filename, $file_nickname, $header_ref, $field_extractor, $matrix_field_extractor) = @_;

    my @headers;

    my $zone_order_index = 1;
    open(my $fh, $filename) or die("Couldn't open file '$filename': $!\n");
    for(my $line_no = 0; my $row = $csv->getline($fh); $line_no++)	
	{
		# Make sure the header looks sane... it's an easy check, but it'll catch obvious mistakes
		if ($line_no == 0)
		{
            # iterate through the headers that were provided in the arguments and make sure they match
            # what's in the file.
			for(my $col = 0; $col < scalar(@{$header_ref}); $col++)
			{
				if ($row->[$col] ne $header_ref->[$col])
				{
					die("CSV header does not match for $file_nickname file (found '" 
                       . $row->[$col] ."' expected '" . $header_ref->[$col] . "')\n");
				}
                push @headers, $row->[$col];
			}	


            # If this is going to be a matrix'd CSV, those headers will follow the main headers
            for(my $col = scalar(@{$header_ref}); $col < scalar(@{$row}); $col++)
            {
                push @headers, $row->[$col];
            }

		}
        else  ## Process an actual data row...
        {

            my $chan_config = $field_extractor->($row);
            my $zone_name = $chan_config->{+CHAN_SCANLIST_NAME};

            # non-matrixed CSV files:
            if (scalar(@{$header_ref}) == scalar(@{$row}))
            {
                # This area applies to the Analog and "Other DMR" inputs...
                # Each of those files has a "zone" column.  We'll create a zone and a scanlist with all the channels
                # listed in the specified zone.
                # ... this is a hack and shouldn't live here =/
                my $scanlist_name = $chan_config->{+CHAN_SCANLIST_NAME};

                add_channel($out_fh, $chan_config, $zone_name, $scanlist_name, $zone_order_default);
            }

            # matrixed CSV files... so iterate through each of the extra headers, which are the talk groups...
            for (my $col = scalar(@{$header_ref}); $col < scalar(@{$row}); $col++)
            {
                if (!defined($matrix_field_extractor))
                {
                    die("There are too many columns in '$filename'.\n");
                }
                my ($do_matrix, $chan_config) = $matrix_field_extractor->($chan_config, $headers[$col], $row->[$col]);


                if ($do_matrix)
                {
                    # For the repeaters, we create a zone per repeater, and a scanlist for each talkgroup (which allows
                    # us to scan this talkgroup across all repeaters).  We also set the scanlist_name to the talkgroup
                    # so that when we hit scan, we actually scan the right thing ;-P
                    #
                    # again, this is a hack and shouldn't live here.
                    my $scanlist_name = $chan_config->{+CHAN_CONTACT};
                    $chan_config->{+CHAN_SCANLIST_NAME} = $scanlist_name;

                    $chan_config->{+CHAN_TX_PERMIT} = tx_permit($chan_config);

                    add_channel($out_fh, $chan_config, $zone_name, $scanlist_name, $zone_order_index);
                }
            }
            $zone_order_index++;
        }
	}
}


sub add_channel
{
    my ($out_fh, $chan_config, $zone_name, $scanlist_name, $zone_order_index) = @_;

    my @output;

    foreach my $index (sort {$a <=> $b} keys %channel_csv_default_value)
    {
        my $value = $channel_csv_default_value{$index};
        if(defined($chan_config->{$index}))
        {
            $value = $chan_config->{$index};
        }
        if ($index == CHAN_NUM)
        {
            $value = $global_channel_number++;
        }

        $chan_config->{$index} = $value;

        if ($value eq "REQUIRED")
        {
            die("I need a value for '" . $channel_csv_field_name{$index} . "'\n");
        }

        push @output, $value; 
    } 

    $csv->print($out_fh, \@output);

    build_zone_config(     $chan_config, $zone_name, $zone_order_index);
    build_scanlist_config( $chan_config, $scanlist_name);
    build_talkgroup_config($chan_config);
}


sub build_zone_config
{
    my ($chan_config, $zone_name, $zone_order_index) = @_;

    my $chan_name = $chan_config->{+CHAN_NAME};
    my $rx_freq   = $chan_config->{+CHAN_RX_FREQ};
    my $tx_freq   = $chan_config->{+CHAN_TX_FREQ};
    
    $zone_order{$zone_name} = $zone_order_index;

    my $order = channel_order_name($chan_config);
    push @{$zone_config{$zone_name}}, join("\t", $order, $chan_name, $rx_freq, $tx_freq);
}


sub build_scanlist_config
{
    my ($chan_config, $scanlist_name) = @_;

    my $chan_name = $chan_config->{+CHAN_NAME};
    my $rx_freq   = $chan_config->{+CHAN_RX_FREQ};
    my $tx_freq   = $chan_config->{+CHAN_TX_FREQ};

    my $order = channel_order_name($chan_config);
    push @{$scanlist_config{$scanlist_name}}, join("\t", $order, $chan_name, $rx_freq, $tx_freq);
}



sub build_talkgroup_config
{
    my ($chan_config) = @_;

    my $talkgroup = $chan_config->{+CHAN_CONTACT};

    if (!defined($talkgroup_mapping{$talkgroup}))
    {
        die("Talkgroup '$talkgroup' is referenced by not defined in the talkgroup CSV file\n");
    }

    $talkgroup_config{$talkgroup} = 1;
}


sub channel_order_name
{
    my ($chan_config) = @_;

    my $index = $zone_order_default;
    my $chan_name = $chan_config->{+CHAN_NAME};

    if ($global_sort_mode ne 'alpha' && $chan_config->{+CHAN_MODE} eq VAL_DIGITAL)
    {
        if (defined($talkgroup_order{$chan_config->{+CHAN_CONTACT}}))
        {
            $index = $talkgroup_order{$chan_config->{+CHAN_CONTACT}};
        }
    }

    return sprintf("%04d%s", $index, $chan_name);

}


sub tx_permit
{
    my ($chan_config) = @_;

    my $result = VAL_TX_PERMIT_SAME;
    if($global_hotspot_tx_permit eq "always" && $chan_config->{+CHAN_RX_FREQ} eq $chan_config->{+CHAN_TX_FREQ})
    {
        $result = VAL_TX_PERMIT_ALWAYS;
    }

    return $result;
}





################################################################################
################################################################################
################################################################################
##########   DATA VALIDATION ROUTINES
################################################################################
################################################################################
################################################################################

sub validate_bandwidth
{
    my ($mode) = @_;

    my %valid_modes = ( "25K" => 1, "12.5K" =>1 );

    return _validate_membership($mode, \%valid_modes, "Analog Mode");
}

sub validate_call_type
{
    my ($call_type) = @_;
    
    my %valid_call_types = ("Private Call" => 1, "Group Call" => 1);
    
    return _validate_membership($call_type, \%valid_call_types, "Call Type");    
}

sub validate_channel_name
{
    my ($contact) = @_;

    return _validate_string_length('Channel Name', $contact, 16);

}

sub validate_color_code
{
    my ($color_code) = @_;
    return _validate_num_in_range("Color Code", $color_code, 0, 16);
}


sub validate_contact
{
    my ($contact) = @_;

    return _validate_string_length("Contact (aka Talk Group)", $contact, 16);
}

sub validate_ctcss
{
    my ($ctcss) = @_;
    return $ctcss if ($ctcss eq 'Off');
    return $ctcss if ($ctcss =~ /D[0-9A-Za-z]+/ && length($ctcss) < 10); # DCS tones, could be smarter
    return _validate_num_in_range('CTCSS/DCS', $ctcss, 0, 300); # this could be smarter
}

sub validate_freq
{
    my ($freq) = @_;
    return _validate_num_in_range('Frequency', $freq, 0, 500); # this could be smarter too
}

sub validate_name
{
	my ($name) = @_;

	return _validate_string_length('Channel Name', $name, 16);
}

sub validate_power
{
    my ($power) = @_;

    my %valid_power_levels = ("Low" => 1, "Mid" => 1, "High" => 1, "Turbo" => 1);

    return _validate_membership($power, \%valid_power_levels, "Power Level");
}

sub validate_timeslot
{
    my ($timeslot) = @_;

    my %valid_timeslots = ("1" => 1, "2" => 1, "-" => 1);

    return _validate_membership($timeslot, \%valid_timeslots, "Time Slot");
}

sub validate_tx_permit
{
    my ($tx_permit) = @_;

    my %valid_tx_permits = ("Always" => 1, "Same Color Code" => 1, "Different Color Code" => 1);

    return _validate_membership($tx_permit, \%valid_tx_permits, "TX Permit");
}

sub validate_tx_prohibit
{
    my ($tx_prohibit) = @_;
    
    return _validate_on_off($tx_prohibit, "TX Prohibit");
}

sub validate_zone
{
	my ($zone) = @_;

	return _validate_string_length('Zone', $zone, 16);
}

sub validate_sort_mode
{
    my ($sort_order) = @_;

    my %valid_sort_orders = ("alpha" => 1, "repeaters-first" => 1, "analog-first" => 1);

    return _validate_membership($sort_order, \%valid_sort_orders, "Sort Order");
}

sub validate_hotspot_mode
{
    my ($hotspot_mode) = @_;

    my %valid_modes = ("always" => 1, "same-color-code" => 1);

    return _validate_membership($hotspot_mode, \%valid_modes, "Hotspot TX Permit");
}

####
# Validation Helpers
####

sub _validate_membership
{
    my ($value, $set_ref, $error) = @_;

    if (!$set_ref->{$value})
    {
        $error  = "Invalid $error: ";
        $error .= "'$value' is not one of: ";
        $error .= join(", ", keys %{$set_ref}) . "\n";
        die($error);
    }

    return $value;
}

sub _validate_num_in_range
{
    my ($type, $value, $min, $max) = @_;

    if (!looks_like_number($value) || $value < $min || $value > $max)
    {
        die("Invalid $type: '$value' must be an number between $min and $max (inclusive)\n");
    }

    return $value;
}

sub _validate_on_off
{
    my ($value, $error) = @_;
    my %valid_on_off = ("On" => 1, "Off" => 1);
    
    return _validate_membership($value, \%valid_on_off, $error);
}

sub _validate_string_length
{
	my ($type, $string, $length) = @_;

	if(length($string) > $length)
	{
		die("Invalid $type: '$string' is more than $length characters\n");
	}

    return $string;
}






################################################################################
################################################################################
################################################################################
##########   GENERIC STUFF: usage(), command-line args, etc
################################################################################
################################################################################
################################################################################
sub handle_command_line_args
{
    my ($analog_filename, $digital_others_filename, $digital_repeaters_filename, $talkgroups_filename);
    my ($config_directory, $output_directory);

    GetOptions("analog-csv=s"             => \$analog_filename,
               "digital-others-csv=s"     => \$digital_others_filename,
               "digital-repeaters-csv=s"  => \$digital_repeaters_filename,
               "talkgroups-csv=s"         => \$talkgroups_filename,
               "config:s"                 => \$config_directory,
               "output-directory=s"       => \$output_directory,
               "sorting:s"                => \$global_sort_mode,
               "hotspot-tx-permit:s"      => \$global_hotspot_tx_permit,)
        or usage();

    validate_sort_mode($global_sort_mode);
    if ($global_sort_mode eq "analog-first")
    {
        $zone_order_default = 0;
    }

    validate_hotspot_mode($global_hotspot_tx_permit);

    if (!defined($analog_filename) || !defined($digital_others_filename) || !defined($digital_repeaters_filename)
        || !defined($talkgroups_filename) || !defined($output_directory))
    {
        usage();
    }

    if (!defined($config_directory))
    {
        $config_directory = "config";
    }

    return ($analog_filename, $digital_others_filename, $digital_repeaters_filename, $talkgroups_filename,
            $config_directory, $output_directory);
}


sub usage
{
    print "$0 \n";
    print "arguments:\n";
    print "  --analog-csv=<analog.csv>  \n";
    print "  --digital-others-csv=<digital-others.csv>\n";
    print "  --digital-repeaters-csv=<digital_repeaters.csv> \n";
    print "  --talkgroups-csv=<talkgroups.csv> \n";         
    print "  --output-directory=<output-directory>\n";
    print "  [--config=<config file>]\n";
    print "  [--sorting=(alpha|repeaters-first|analog-first)]\n";
    print "  [--hotspot-tx-permit=(always|same-color-code)]\n";
    exit -1;
}
