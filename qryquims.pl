#!/usr/bin/perl -l

use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
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
    my $json;

    $sth=$dbh->prepare("SELECT cuim,done,json FROM cuimuri WHERE cuim='$cuim'");
    $rep=$sth->execute();

    return 0 unless $rep >= 0;

    @cm=$sth->fetchrow_array();

    # skip records without json / invalid CUIM
    return 2 unless $cm[1]==1;

    # print "$cuim: $cm[1]";

    $json= JSON->new->utf8->decode($cm[2]);

    my $x=$json->{'data'}->{'results'}[0];

    my $out="";

    append_wc(\$out,$cuim);
    append_wc(\$out,${$x}{'nume'});
    append_wc(\$out,${$x}{'initiala'});
    append_wc(\$out,${$x}{'prenume'});
    append_wc(\$out,${$x}{'nume_anterior'});

    my @spec=@{${$x}{'specialitati'}};
    unless( ($#spec+1) != 0){
        # execute when no "specialitati"
        $out.=",,,,,,,,,";
    }else{
        append_wc(\$out,$spec[0]->{'grad'});
        append_wc(\$out,$spec[0]->{'nume'});
        append_nc(\$out,$spec[0]->{'drept_de_practica'});

        if(defined($spec[1])){
            append_nc(\$out,",");
            append_wc(\$out,$spec[1]->{'grad'});
            append_wc(\$out,$spec[1]->{'nume'});
            append_nc(\$out,$spec[1]->{'drept_de_practica'});
        }
    }
    print $out;
    # unless ($cuim !~ /2791470903/) {
    #     print $out ;
    #     print Dumper $x;
    # }
    return 1;
}

#----------------------------------------------------------------
sub append_wc { #append string, then append a comma
    my $str=shift;
    my $tmp=shift;

    if(defined($tmp)){
        # comma in the name, quote string
        if($tmp =~ m/\,/) {
            $tmp=qq("$tmp");
        }
        ${$str}=${$str}.$tmp.",";
    }else{
        ${$str}=${$str}.",";
    }
}

#----------------------------------------------------------------
sub append_nc { #append string, no comma
    my $str=shift;
    my $tmp=shift;

    if(defined($tmp)){
        ${$str}=${$str}.$tmp;
    }
}

#----------------------------------------------------------------
sub query_missing_cuims {

    print "CUIM,Nume,Initiala,Prenume,Nume Anterior,".
        "Grad (1),Specializare (1), Drept Practica (1),".
        "Grad (2),Specializare (2), Drept Practica (2)";
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
        # print "INFO: using $dbfile database.\n";
    } else {
        # print "ERR: Cannot find database $dbfile. Exit.\n";
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
# print "----------------------------------\n";
# print " CUIM DB Query v0.1\n";
# print "----------------------------------\n";

open_database();
read_cuims_from_text();
query_missing_cuims();
close_database();

# print "CUIMS processed: $count\n";

