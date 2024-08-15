#!/usr/bin/perl
use strict;
use warnings;

# Verifică argumentele din linia de comandă
die "Usage: perl sts.pl <input_genbank_file> <output_file>\n" unless @ARGV == 2;

my ($fisier_intrare, $fisier_iesire) = @ARGV;

open(my $intrare, '<', $fisier_intrare) or die "Nu pot deschide fișierul $fisier_intrare: $!";
open(my $iesire, '>', $fisier_iesire) or die "Nu pot deschide fișierul $fisier_iesire: $!";

# Variabile pentru a urmări secțiunile FEATURES și ORIGIN
my $in_features = 0;
my $in_origin = 0;
my $secventa = '';
my %caracteristici_sts;

# Procesarea fișierului de intrare
while (my $linie = <$intrare>) {
    chomp $linie;
    if ($linie =~ /^FEATURES/) {
        $in_features = 1;
    } elsif ($linie =~ /^ORIGIN/) {
        $in_features = 0;
        $in_origin = 1;
    } elsif ($in_features && $linie =~ /^ {5}STS\s+(complement\()?(\d+)\.\.(\d+)/) {
        my $locatie = $2 . ".." . $3;
        $caracteristici_sts{$locatie} = '';
    } elsif ($in_origin && $linie =~ /^\s*\d+\s+([acgt\s]+)/i) {
        my $parte_secventa = $1;
        $parte_secventa =~ s/\s//g;
        $secventa .= $parte_secventa;
    }
}

# Solicitarea intervalului de la utilizator
print "Specificați porțiunea de interes (utilizați : pentru descrierea intervalului): ";
my $interval = <STDIN>;
chomp $interval;
my ($inceput_interval, $sfarsit_interval) = split(/:/, $interval);

# Extragerea secvențelor pentru fiecare caracteristică STS
foreach my $locatie (keys %caracteristici_sts) {
    if ($locatie =~ /(\d+)\.\.(\d+)/) {
        my $inceput = $1 - 1;
        my $lungime = $2 - $inceput;
        
        # Verifică dacă STS-ul se încadrează în intervalul specificat de utilizator
        if ($1 >= $inceput_interval && $2 <= $sfarsit_interval) {
            $caracteristici_sts{$locatie} = substr($secventa, $inceput, $lungime);
        }
    }
}

# Scrierea informațiilor descriptive în fișierul de ieșire
seek($intrare, 0, 0);  # Revin la începutul fișierului de intrare pentru a re-citi secțiunile descriptive
my $in_features_start = 0;
while (my $linie = <$intrare>) {
    chomp $linie;
    if ($linie =~ /^FEATURES/) {
        last;
    } else {
        print $iesire "$linie\n";
    }
}

# Scrierea caracteristicilor STS și a secvențelor lor în fișierul de ieșire
foreach my $locatie (sort keys %caracteristici_sts) {
    if ($caracteristici_sts{$locatie}) {
        print $iesire "Location: $locatie\nSequence: $caracteristici_sts{$locatie}\n\n";
    }
}

close $intrare;
close $iesire;

print "Procesarea s-a încheiat. Datele au fost salvate în $fisier_iesire\n";
