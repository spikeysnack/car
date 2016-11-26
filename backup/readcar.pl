#!/usr/bin/perl -w

#readcar.pl

#use strict;
#use strict "vars";
use warnings;

# read the binary car file and get the catalog
sub read_cat_from {

    my (@args) = @_;
    my $catbuf;    
    my $osf = 20;
    my $filename = $args[0] ;
    my(@catalog);

    use Fcntl qw(:seek); # 'SEEK_SET'  'SEEK_CUR' 'SEEK_END';

    open FH, "<", $filename or die "seek:$!" ;

    binmode(FH, ":raw");
    # read file len of catalog (20 bytes)
    sysseek (FH , -$osf , SEEK_END); 
    read(FH, $catbuf, $osf);


     # my( $hex ) = unpack( 'H*', $catbuf ); 
     # print "$hex\n";

    my($asc)   = unpack( 'A*', $catbuf); #convert to ascii
    # print "$asc\n";

    my($garbage, $catlen) = split /\n/, $asc; # split it and keep len
    undef $garbage; # throw away

    # print "$catlen\n";
    my $catpos = $catlen + length($catlen) + 1;

    sysseek (FH , -($catpos) , SEEK_END); # go to begin of catalog

    read(FH, $catbuf, $catlen);  # read the catalog

    @catalog =  split (/\n/, $catbuf);
    
    return @catalog ;

}


#output hashes in an array
sub print_array_of_hash {
    my @args = @_;

    foreach my $a_item  (@args) {	
	%hitem = %{$a_item};            # convert to hash
	my @hkeys = keys %hitem;        # get keys
	for my $key (@hkeys){
	    print "\t $key :  $hitem{$key}\n"; 
	}
	print "\n";	    
    }
}


sub print_hash {

    my (@args) = @_; 
    my %h = %{$args[0]};
    my @keys = @args[1..$#args];

    my $v;
    for my $k (@keys) {
    	$v = ($h{$k});
       printf "\t$k:\t$v\n"
    }

}# print_hash




#extracts data from an array of parens
sub in_parens {

    my $parenregex = qr/\(([^\)]+)/; #inside '(' and ')'
    my (@args) = @_;
    my @out;

    for my $e (@args){
	my ($f) = $e =~ $parenregex ; # yeild inside of parens	
	push @out, $f;
    }
    return @out;
}



# split into parts / return hash of data
sub car_entry {

    my (@args) = @_;

    my ($_name, $_size, $_mimetype, $_file_hash) = split /:/, $args[0];
        
    my ($name, $size, $mimetype, $file_hash) = in_parens($_name, $_size, $_mimetype, $_file_hash);
    
    my %car_file = (
        'name' => $name,
        'size' => $size,
        'mimetype' => $mimetype,
        'file_hash' => $file_hash);

    return %car_file;  
}


sub main
{

    my (@cmdargs) = @ARGV; # get args from shell

    my (@catalog) = read_cat_from( $cmdargs[0]) ; # contents of carfile catalog (array)

    my @ent_array;


    for my $car_entry (@catalog) {
    
	my (%ent) = car_entry($car_entry);
 
	push @ent_array, \%ent ;  # push reference
    }

# print_array_of_hash( @ent_array );

# print keys specified in order
    for my $h (@ent_array) {
	print_hash( $h, "name", "size", "mimetype", "file_hash" );
	print("\n");
    }
    
    exit 0
}



my $status= main( @ARGV );

exit $status;

# end

    



 

 










    


