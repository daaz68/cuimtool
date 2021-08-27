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
my $inserts=0;

#----------------------------------------------------------------
sub clean_cuim {
    my $cuim=shift;

    $cuim =~ s/[\n\r]//g;

    return $cuim;
}

#----------------------------------------------------------------
sub check_cuim_exists {
    my $cuim=shift;

    $sth=$dbh->prepare("SELECT cuim FROM cuimuri WHERE cuim='$cuim'");
    $sth->execute();

    return 0 unless defined($sth->fetch());

    return 1;
}

#----------------------------------------------------------------
sub insert_cuim {
    my $cuim=shift;

    $sth=$dbh->prepare("INSERT INTO cuimuri (cuim,done) VALUES ($cuim,0)");
    $sth->execute();

}

#----------------------------------------------------------------
sub insert_missing_cuims {

    foreach my $cuim (@cuims) {
        next unless length($cuim);

        $cuim=clean_cuim($cuim);

        if(!check_cuim_exists($cuim)) {
            $inserts++;
            insert_cuim($cuim);
        }
    }
}

#----------------------------------------------------------------
sub close_database {
    $sth->finish();
    $dbh->disconnect();
}

#----------------------------------------------------------------
sub create_open_database {
    my @dbs;
    my $dbfound=0;

    binmode(STDOUT,":utf8");

    if ( -e $dbfile ) {
        print "INFO: Database file $dbfile exists.\n";
        $dbfound=1;
        # unlink $dbfile if -e $dbfile;
    } else {
        print "INFO: Creating database file $dbfile.\n";
    }

    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");

    if(!$dbfound){
        my $qr=<<'SCHEMA';
CREATE TABLE cuimuri (
    cuim_id INTEGER PRIMARY KEY AUTOINCREMENT,
    cuim VARCHAR(100),
    done INTEGER,
    json BLOB,
    UNIQUE(cuim)
    );
SCHEMA
        $sth=$dbh->prepare($qr);
        $sth->execute();
    }

    $sth=$dbh->prepare('pragma table_info(cuimuri)');
    $sth->execute();

    while (my $row=$sth->fetchrow_arrayref()){
        push @dbs, @$row[1];
    }
    # print Dumper(@dbs);
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
print " CUIM DB Creator v0.1\n";
print "----------------------------------\n";

create_open_database();
read_cuims_from_text();
insert_missing_cuims();
close_database();

print "New records inserted: $inserts\n";


=for comment
    if(!$dbfound){
        my $qr=<<'SCHEMA';
CREATE TABLE cuimuri (
    cuim_id INTEGER PRIMARY KEY,
    cuim VARCHAR(100),
    nume VARCHAR(100),
    prenume VARCHAR(100),
    initiala VARCHAR(100),
    done INTEGER,
    json VARCHAR(4096),
    UNIQUE(cuim)
    );
SCHEMA
=cut
