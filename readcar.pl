#!/usr/bin/perl -w

#readcar.pl
use strict;
use warnings;

=head1 NAME

readcar.pl - reads a car archive and outputs its catalog

=head1 SYNOPSIS

    perl readcar.pl <carfile>


=head1 DESCRIPTION

readcar.pl  takes in a car archive name as an argument

and extract its catalog from the end of the file.

The last item in the archive is the size in bytes of 

the catalog file, which is a text file containing the 

following information, (at this time):

=head1 CATALOG FORMAT 

B<TYPE(data)> separated by a colon  B<":">  and each entry on one line.

=over 4

=item NAME  
the file name
    
=item SIZE
The file size in bytes

=item MIMETYPE
a short string from the command C<file -i <file? | cut -d ' ' -f1>

=item FILEHASH
a hash number  

(md5sum is used but any good hash will work. MD5 exists on all platforms and in online tools as well)

=back

=head2  EXAMPLE 

C<NAME(vid.mp4):SIZE(1432232):MIMETYPE(video/mp4; charset=binary):MD5SUM(1f5c99b03b6b90cfb7d906a6a2daf50a)>


=head3 ADDITIONAL CATALOG ITEMS

Additional catalog items of the format C<"NAME(I<"data">)"> are fine if they are useful. 

Good examples might be  OWNER, PERMISSIONS, DATE, SUMMARY, and so on. 

However, before things get too wordy, perhaps a table of contents added to the archive
would serve better. 
    
Excessively long lines in text files should be avoided.

Perhaps the format could be changed so that if a line begins with a colon ":"  
or an asterix "*",  then it is considered a  continuation of the previous line?  


=head1 METHODS

=over 4

=item C<read_cat_from>


Opens the file and retrieves the catalog byte size from the end of the file.

20 bytes are possible for a catalog size, so 20 bytes are read.

The 20 bytes are then converted to ASCII and split on the newline "\n"

character and the length is kept and the earlier part is discarded.

The catalog is then read based on its size and offset in the car archive.

The catalog items are put into an array line by line.

The file is closed  and the array is returned.

=item C<car_entry>


Splits a catalog entry into its component parts,

extracting the data into variables and then

accumulating it into a hash record.

The hash is returned.

=back

=head2 Minor Methods

=over 4

=item C<in_parens>


An array of items is input containing data in parentheses.

The data is extracted and returned. 

=item C<print_hash>


Prints out a hash as its component parts

It takes as input a hash and an array of keys.

This allows keyes to be ignored, and additionally

specifies the order in which they are printed, 

because in perl hashes are unordered, so you do not

know what order they will be in. This ensures you

get what you want in the right order.


=item C<main>

drives the program 

=back
  
=cut


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
	my %hitem = %{$a_item};            # convert to hash
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
    
#    my (@hashkeys) = keys %h;

    my $v;
    for my $k (@keys) {
	$v = ($h{$k}) if exists $h{$k};    	 
	printf "\t$k:\t$v\n" if $v;
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

    



 

 










    


