<?php
error_reporting( E_ALL );
ini_set('display_errors', 1);

if(!isset($_FILES["analog"])) {
    header("Location: ./");
    exit(0);
}


print_html_start();

$sort_order = validateSortOrder($_POST["sort"]);
$hotspot_tx_permit = validateHotSpotTXPermit($_POST["hotspot"]);
$analog  = fileValidation("Analog",            $_FILES["analog"]);
$dmr_oth = fileValidation("Digital-Others",    $_FILES["digitalothers"]);
$dmr_rep = fileValidation("Digital-Repeaters", $_FILES["digitalrepeaters"]);
$talkgrp = fileValidation("TalkGroups",        $_FILES["talkgroups"]);

$outdir = tempdir("dmr-output-");


exec("./anytone-config-builder.pl --analog-csv='$analog' "
     . "--digital-others-csv='$dmr_oth' --digital-repeaters-csv='$dmr_rep' --talkgroups-csv='$talkgrp' "
     . "--output-directory='$outdir' --sorting=$sort_order --hotspot-tx-permit=$hotspot_tx_permit 2>&1", 
     $output, $return);


foreach($output as $line)
{
    if (preg_match('/^WARNING: (.*)/', $line, $matches))
    {
        print_html_div("WARNING", "#FFFFBB", $matches[1]);
    }
    elseif (preg_match('/^ERROR: (.*)/', $line, $matches))
    {
        print_html_div("ERROR", "#FFDDDD", $matches[1]);
    }
}


if ($return == 0)
{
    print_html_div("SUCCESS", "#DDFFDD", "It worked!  Your files should be downloading now.");
    print "<iframe style='display:none;' src='download.php?name=$outdir'></iframe>";
}


function fileValidation($description, $file_details)
{
    $file_type = $file_details["type"];
    $tmp_name  = $file_details["tmp_name"];
    $size      = $file_details["size"];

    if ($size == 0)
    {
        fatal("$description file is empty... did you forget to upload it?");
    }
    if ($size > (1024*1024))
    {
        fatal("$description file is > 1MB.  That's bigger than I'm cool with :D");
    }

    return $tmp_name;
}

function tempdir($prefix='') {
    $tempfile=tempnam(sys_get_temp_dir(), $prefix);
    // you might want to reconsider this line when using this snippet.
    // it "could" clash with an existing directory and this line will
    // try to delete the existing one. Handle with caution.
    if (file_exists($tempfile)) { unlink($tempfile); }
    mkdir($tempfile);
    if (is_dir($tempfile)) { return $tempfile; }
}


function validateSortOrder($sort_order)
{
    if ($sort_order == "alpha" ||
        $sort_order == "repeaters-first" || 
        $sort_order == "analog_first" )
    {
        return $sort_order;
    }
    else
    {
        return 'alpha';
    }
}

function validateHotSpotTXPermit($hotspot)
{
    if ($hotspot == "always" || $hotspot == "same-color-code")
    {
        return $hotspot;
    }
    else
    {
        return "same-color-code";
    }
}

function fatal($message)
{
    print_html_div("ERROR", "#FFDDDD", $message);
    print_html_end();
}


function print_html_start()
{
?>
<html>
<head>
<title>Anytone Config Builder</title>
  <link rel="stylesheet" href="pandoc.css" type="text/css" />
</head>
<body>

<h1>K7ABD's Anytone Config Builder</h1>

<?php
}

function print_html_div($description, $color, $message)
{
    print "$description:<div style='background-color:$color; border: 1px solid #888888; padding: 5px; margin-top: 0px; margin-bottom: 5px;'>$message</div>";
}

function print_html_end()
{
    print "</body></html>";
    exit(0);
}
?>
