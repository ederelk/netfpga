##By Yaovi E.Kwasi####
##yk73@njit.edu#######

use XML::LibXML;
use Math::Int64 qw(int64 uint64);
use Math::Int64 qw( hex_to_uint64 uint64_to_hex );

my $filename = "dag.xml";
my $hexi = "0x";
my $ip_id = "0";
my $control = 0;
my $parser = XML::LibXML->new();
my $xmldoc = $parser->parse_file($filename);

for my $sample ($xmldoc->findnodes('/pdml/packet')) {
 for my $property ($sample->findnodes('proto/field[@name="ip.id"]' )) {
 	#my $name1 = $property->findnode('[@name="ip.id"]') ;
	 $ip_id = $property->getAttribute('value');
	 	 $ip_id = $hexi.$ip_id;
 	 $ip_id = hex($ip_id);

	
 	}
 	for my $property ($sample->findnodes('proto/field[@name="frame.time_delta"]' )) {
 	
	my $timestamp = $property->getAttribute('show');
        print $timestamp,"\t",$ip_id,"\n";
	#print $dec_timestamp, "\t",$test,"\n";
}


		
    }
