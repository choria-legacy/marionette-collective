#!perl
use strict;
use Test::More;
use JSON;
use File::Temp;

my $class = "MCollective::Action";
use_ok( $class );

my $infile  = File::Temp->new;
my $outfile = File::Temp->new;

$ENV{MCOLLECTIVE_REQUEST_FILE} = $infile->filename;
$ENV{MCOLLECTIVE_REPLY_FILE}   = $outfile->filename;
print $infile JSON->new->encode({ red => "apples", blue => "moon" });
close $infile;
{
    my $mc = $class->new;
    isa_ok( $mc, $class );
    is( $mc->request->{red}, "apples", "apples are red" );
    $mc->reply->{potato} = "chips";
}

my $json = do { local $/; <$outfile> };
ok( $json, "Got some JSON" );
my $reply = JSON->new->decode( $json );

is( $reply->{potato}, "chips", "Got the reply that potato = chips" );

done_testing();
