<?php
error_reporting( E_ALL );
ini_set('display_errors', 1);

if(!isset($_FILES["analog"])) {
    header("Location: ./");
    exit(0);
}




$sort_order = validateSortOrder($_POST["sort"]);
$analog  = fileValidation("Analog",            $_FILES["analog"]);
$dmr_oth = fileValidation("Digital-Others",    $_FILES["digitalothers"]);
$dmr_rep = fileValidation("Digital-Repeaters", $_FILES["digitalrepeaters"]);
$talkgrp = fileValidation("TalkGroups",        $_FILES["talkgroups"]);

$outdir = tempdir("dmr-output-");


system("./anytone-config-builder.pl --analog-csv='$analog' "
     . "--digital-others-csv='$dmr_oth' --digital-repeaters-csv='$dmr_rep' --talkgroups-csv='$talkgrp' "
     . "--output-directory='$outdir' --sorting=$sort_order 2>&1", $return);

if ($return == 0)
{
    exec("zip -jr $outdir.zip $outdir/");

    header("Pragma: public");
    header("Expires: 0");
    header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
    header("Cache-Control: public");
    header("Content-Description: File Transfer");
    header("Content-type: application/octet-stream");
    header("Content-Disposition: attachment; filename=\"anytone.zip\"");
    header("Content-Transfer-Encoding: binary");
    header("Content-Length: ".filesize("$outdir.zip"));
    ob_end_flush();
    @readfile("$outdir.zip");
    unlink("$outdir.zip");
}

exec("rm -rf $outdir");

function fileValidation($description, $file_details)
{
    $file_type = $file_details["type"];
    $tmp_name  = $file_details["tmp_name"];
    $size      = $file_details["size"];

    if ($size == 0)
    {
        print "$description file is empty... did you forget to select it?";
        exit();
    }
    if ($size > (1024*1024))
    {
        print "$description file is > 1MB.  That's bigger than I'm cool with :D";
        exit();
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
?>
