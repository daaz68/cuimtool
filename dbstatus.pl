#!/usr/bin/perl -l

use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON::Parse 'parse_json';
use DBI qw(:sql_types);

my $ua;
my $dbh;
my $sth;
my $dbfile="cuim.sqlt";
my @cuims;
my $inserts=0;
my $req;
my $row;
my $count;

#----------------------------------------------------------------
sub close_database {
    $sth->finish();
    $dbh->disconnect();
}

#----------------------------------------------------------------
sub open_database {

    $ua = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0 },
        protocols_allowed => ['https'],
    );

    binmode(STDOUT,":utf8");

    if ( ! -e $dbfile ) {
        print "ERR Cannot find $dbfile database. Exit.\n";
    }

    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
}

#----------------------------------------------------------------
sub get_cuim_json {
    my $cuim=shift;

    $req = HTTP::Request->new(
        GET => "https://regmed.cmr.ro/api/v2/public/medic/cautare/$cuim",
    );

    my $res = $ua->request($req);

    my $js=parse_json($res->content);

    if($js->{data}->{total}){
        my $st=$dbh->prepare("UPDATE cuimuri SET done=1, json=? WHERE cuim = '$cuim'");
        $st->bind_param(1, $res->content, SQL_BLOB);
        $st->execute();
        print ">>> $cuim json saved.";
    } else {
        return 1 unless $js->{message} !~ /per 1 day/;
        my $st=$dbh->prepare("UPDATE cuimuri SET done=2 WHERE cuim = '$cuim'");
        $st->execute();
    }
    return 0;
}

#=================================================================
#
open_database();

# count the records to be processed
$sth=$dbh->prepare("SELECT count(*) FROM cuimuri WHERE done=0");
$sth->execute();
($count)=$sth->fetchrow_array;
printf "In work: %5d\n",$count;

$sth=$dbh->prepare("SELECT count(*) FROM cuimuri WHERE done=2");
$sth->execute();
($count)=$sth->fetchrow_array;
printf "Invalid: %5d\n",$count;

$sth=$dbh->prepare("SELECT count(*) FROM cuimuri WHERE done=1");
$sth->execute();
($count)=$sth->fetchrow_array;
printf "  Valid: %5d\n",$count;

close_database();

=for comment
    my $sth = $dbh->prepare('INSERT INTO Gene VALUES (?, ?, ?, ?, ?)');
    $sth->execute(undef, $sequence, $siteNumber, $begin, $length);

[
    {
        "tara": "Rom\\u00e2nia",
        "prenume": "IULIA-MONICA",
        "initiala": "C ",
        "specialitati":
        [
            {
                "grad": "Primar",
                "drept_de_practica": "Drept de liber\\u0103 practic\\u0103 (1)",
                "nume": "RADIOLOGIE - IMAGISTIC\\u0102 MEDICAL\\u0102"
            }
        ],
        "loc_de_munca":
        [
            {"nume": "SC NEW AID SRL"},
            {"nume": "Spitalul Judetean de Urgenta"},
            {"nume": "SC DR NECULA SRL"},
            {"nume":"Muntenia Medical Competences SA"}
        ],
        "restrangeri": [],
        "studii_complementare":
        [
            {"nume": "IMAGISTIC\\u0102 PRIN REZONAN\\u021a\\u0102 MAGNETIC\\u0102"},
            {"nume": "TOMOGRAFIE COMPUTERIZAT\\u0102"},
            {"nume": "ECHOGRAFIE GENERAL\\u0102"},
            {"nume": "SENOLOGIE IMAGISTIC\\u0102"}
        ],
        "judet": "Arge\\u0219",
        "nume_anterior": "",
        "status": "Activ",
        "nume": "STAN"
    }
]
    use DBI qw(:sql_types);
    my $dbh = DBI->connect("dbi:SQLite:dbfile","","");

    my $blob = `cat foo.jpg`;
    my $sth = $dbh->prepare("INSERT INTO mytable VALUES (1, ?)");
    $sth->bind_param(1, $blob, SQL_BLOB);
    $sth->execute();

    if($js->{data}->{total}){
        my $st=$dbh->prepare("UPDATE cuimuri SET done=?, nume=?, prenume=?, initiala=? WHERE cuim = '$cuim'");
        $st->execute(
            1,
            $js->{data}->{results}[0]->{nume},
            $js->{data}->{results}[0]->{prenume},
            $js->{data}->{results}[0]->{initiala}
        );
    }
-------------------------------------------
    {"message": "30 per 1 minute"}
    {"message": "100 per 1 day"}
=cut
