<?php
error_reporting( E_ALL );
ini_set('display_errors', 1);

$outdir = $_GET["name"];

if (!preg_match('/^\/tmp\/dmr-output-[A-Za-z0-9]+$/', $outdir))
{
    print "wtf?  $outdir\n";
    exit(0);
}

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

exec("rm -rf $outdir");
?>
