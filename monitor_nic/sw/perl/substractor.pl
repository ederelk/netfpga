##By Yaovi E.Kwasi####
##yk73@njit.edu#######

use XML::LibXML;
use Math::Int64 qw(int64 uint64);
use Math::Int64 qw( hex_to_uint64 uint64_to_hex );
use Math::BigFloat;





my $filename = "netfpga.xml";
my $filename1 = "dag.xml";
my $hexi = "0x";
my $ip_id = "0";
my $t1 = 0;
my $t2 =0;
my $p_second =0;
my $p_nanosecond =0;

my $parser = XML::LibXML->new();
my $xmldoc = $parser->parse_file($filename);
my $parser1 = XML::LibXML->new();
my $xmldoc1 = $parser1->parse_file($filename1);
Math::BigFloat->precision(-9);

for my $sample ($xmldoc->findnodes('/pdml/packet')) {
 for my $property ($sample->findnodes('proto/field[@name="ip.id"]' )) {
 	 $ip_id = $property->getAttribute('value');
 	 $ip_id = $hexi.$ip_id;
 	 $ip_id = hex($ip_id);
 	 $ip_id = $ip_id - 1;
 	}
 for my $property ($sample->findnodes('proto/field[@name="data"]' )) {
 	my $timestamp = $property->getAttribute('value');
 	$timestamp = substr($timestamp,0,16);
	$timestamp= $hexi.$timestamp;
	#$timestamp = hex($timestamp);
	my $dec_timestamp = hex_to_uint64($timestamp);
	#my $dec_timestamp = $timestamp;
	#my $test = uint64_to_hex($dec_timestamp);
	my $second = ($dec_timestamp>>32)& 0xffffffff;
	my $nanosecond = uint64((($dec_timestamp&0xffffffff)*1000000000)>>32);
	my $length = length($nanosecond);
	if($length == 5){
	$nanosecond = "0000".$nanosecond;
	}elsif($length == 6){
	$nanosecond = "000".$nanosecond;
	}elsif($length == 7){
	$nanosecond = "00".$nanosecond;
	}elsif($length == 8){
	$nanosecond = "0".$nanosecond;
	}else{
	}
	
	$t2 = Math::BigFloat->new(($second.".".$nanosecond) *1);
	$t2 = $t2-$t1;
        #my $timestamp_high =  $hexi.substr($timestamp,0,8);
 	#my $timestamp_low =  $hexi.substr($timestamp,7,8);
 	#my $hex_th = hex($timestamp_high);
 	#my $hex_lw = hex($timestamp_low) * 1000000000;
 	 $t1 = Math::BigFloat->new(($second.".".$nanosecond) *1);
 	
        #print $second,".",$nanosecond, "\t",$ip_id,"\n";
        #print $t2, "\t",$ip_id,"\n";
	        #print $t2, "\t",$ip_id,"\n";

       for my $sample1 ($xmldoc1->findnodes('/pdml/packet')) {
        for my $property1 ($sample1->findnodes('proto/field[@name="ip.id"]' )) {
 	
 	
 	 $ip_id1 = $property1->getAttribute('value');
 	 $ip_id1 = $hexi.$ip_id1;
 	 $ip_id1 = hex($ip_id1);
 	}
 	
 	if($ip_id1 == $ip_id){
        for my $property1 ($sample1->findnodes('proto/field[@name="frame.time_delta"]' )){
 	my $timestamp1 = $property1->getAttribute('show');
 	$timestamp1 = Math::BigFloat->new($timestamp1);
	$t2 =$timestamp1 - $t2;
	 print $t2, "\t",$ip_id,"\n";
	#print $t2, "\t",$timestamp1,"\t",$ip_id,"\n";
 	} 
	}else {
	next;
	}
        
	
        }
        
        }
        
        
        $t2 =0;
	#print $dec_timestamp, "\t",$test,"\n";




		}
    


