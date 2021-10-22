#!/usr/bin/perl -l

use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON::Parse 'parse_json';
use DBI;

my $dbh;
my $sth;
my $dbfile="cuim.sqlt";
my $txtfile="cuim.text";
my @cuims;
my $count=0;

#----------------------------------------------------------------
sub clean_cuim {
    my $cuim=shift;

    $cuim =~ s/[\n\r]//g;

    return $cuim;
}

#----------------------------------------------------------------
sub cuim_query {
    my $cuim=shift;
    my $rep;
    my @cm;

    $sth=$dbh->prepare("SELECT cuim,done FROM cuimuri WHERE cuim='$cuim'");
    $rep=$sth->execute();

    return 0 unless $rep >= 0;

    @cm=$sth->fetchrow_array();

    print "$cm[1]";


    return 1;
}

#----------------------------------------------------------------
sub insert_cuim {
    my $cuim=shift;

    $sth=$dbh->prepare("INSERT INTO cuimuri (cuim,done) VALUES ($cuim,0)");
    $sth->execute();

}

#----------------------------------------------------------------
sub query_missing_cuims {

    foreach my $cuim (@cuims) {
        $count++;
        next unless length($cuim);

        $cuim=clean_cuim($cuim);

        cuim_query($cuim);
    }
}

#----------------------------------------------------------------
sub close_database {
    $sth->finish();
    $dbh->disconnect();
}

#----------------------------------------------------------------
sub open_database {
    my @dbs;

    binmode(STDOUT,":utf8");

    if ( -e $dbfile ) {
        print "INFO: using $dbfile database.\n";
    } else {
        print "ERR: Cannot find database $dbfile. Exit.\n";
        exit 1;
    }

    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
}

#----------------------------------------------------------------
sub read_cuims_from_text {
    my $handle;

    unless (open $handle, "<:encoding(utf8)", $txtfile) {
        print STDERR "ERR: Could not open file '$txtfile': $!\n";
        exit 1;
    }
    chomp(@cuims = <$handle>);
    unless (close $handle) {
        # what does it mean if close yields an error and you are just reading?
        print STDERR "Don't care error while closing '$txtfile': $!\n";
    }
}
#================================================================
#
#
print "----------------------------------\n";
print " CUIM DB Query v0.1\n";
print "----------------------------------\n";

open_database();
read_cuims_from_text();
query_missing_cuims();
close_database();

print "CUIMS processed: $count\n";

