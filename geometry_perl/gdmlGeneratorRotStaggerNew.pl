: # feed this into perl *-*-perl-*-*
    eval 'exec perl -S $0 "$@"'
    if $running_under_some_shell;

use Cwd;
use Cwd 'abs_path';
use File::Find ();
use File::Basename;
use Math::Trig;
use Getopt::Std;


### Declare variables explicitly so "my" not needed
use strict 'vars';
use vars qw($opt_F $opt_T $data $line @fields @index @x @y @z @dx @dy @dz @rx @ry @rz @quartzCutAngle @refTopOpeningAngle @dzRef @dxLg @dyLg @dzLg  @lgTiltAngle @dxPmt @dyPmt @dzPmt @wallThick @wtOverlap @pmtWindowThickness @range  $i $j $k $width $calc);

###  Get the option flags.
getopts('F:T:');

if ($#ARGV > -1){
    print STDERR "Unknown arguments specified: @ARGV\nExiting.\n";
    exit;
}


### Reading CSV file containing parameter values
open($data, '<', $opt_F);
$i=0;
while($line= <$data>){
if ($line =~ /^\s*$/) {   # Check for empty lines
    print "String contains 0 or more white-space character and nothing else.\n";
} else {
chomp $line;
@fields = split(",", $line);
$index[$i]=trim($fields[0]);
$x[$i]=trim($fields[1]);
$y[$i]=trim($fields[2]);
$z[$i]=trim($fields[3]);
$dx[$i]=trim($fields[4]);
$dy[$i]=trim($fields[5]);
$dz[$i]=trim($fields[6]);
$rx[$i]=trim($fields[7]);
$ry[$i]=trim($fields[8]);
$rz[$i]=trim($fields[9]);
$quartzCutAngle[$i]=trim($fields[10]);
$refTopOpeningAngle[$i]=trim($fields[11]);
$dzRef[$i]=trim($fields[12]);
$dxLg[$i]=trim($fields[13]);
$dyLg[$i]=trim($fields[14]);
$dzLg[$i]=trim($fields[15]);
$lgTiltAngle[$i]=trim($fields[16]);
$dxPmt[$i]=trim($fields[17]); # Get rid of initial and trailing white spaces
$dyPmt[$i]= trim($fields[18]);
$dzPmt[$i]= trim($fields[19]);
$i=$i+1;
}
}

$width=25;
####################################################


#### start solids 

# Defining the logical volume. Watch out for this. 
open(def, ">", "solids_${opt_T}.xml") or die "cannot open > solids_${opt_T}.xml: $!";
print def "<solids>\n\n";

print def "<box lunit=\"mm\" name=\"boxMotherSol_${opt_T}\" x=\"1000\" y=\"4000\" z=\"4000\"/>\n";

print def "<cone aunit=\"rad\" deltaphi=\"2*pi\" lunit=\"mm\" name=\"coneMotherSol_${opt_T}\" rmax1=\"499\" rmax2=\"499\" rmin1=\"0\" rmin2=\"0\" startphi=\"0\" z=\"20\"/>\n";

print def "<subtraction name =\"logicMotherSol_${opt_T}\">
	<first ref=\"boxMotherSol_${opt_T}\"/> 
	<second ref=\"coneMotherSol_${opt_T}\"/> 
	<position unit=\"mm\" name=\"coneMotherPos_${opt_T}\" x=\"0\" y=\"0\" z=\"0\"\/>
        <rotation unit=\"rad\" name=\"coneMotherRot_${opt_T}\" x=\"0\" y=\"pi/2\" z=\"0\"/>
</subtraction>\n\n";

for $j(0..$i-1){
print def "<box name=\"quartzRecSol_${opt_T}_$j\" x=\"$dx[$j]\" y=\"$dy[$j]\" z=\"$dz[$j]\" lunit= \"mm\" />\n";

print def "<xtru name = \"quartzCutSol_${opt_T}_$j\" lunit= \"mm\" >
 <twoDimVertex x=\"",$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j]))),"\" y=\"",$dx[$j]*(0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j]))),"\" y=\"",$dx[$j]*(-0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(-0.5*tan(abs($quartzCutAngle[$j]))),"\" y=\"",$dx[$j]*(-0.5),"\" />
 <section zOrder=\"1\" zPosition=\"",$dy[$j]*(-0.5),"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"",$dy[$j]*(0.5),"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
</xtru>\n";

print def "<union name=\"quartzSol_${opt_T}_$j\">
    <first ref=\"quartzRecSol_${opt_T}_$j\"/>
    <second ref=\"quartzCutSol_${opt_T}_$j\"/>
    <position name=\"quartzCutSolPos_${opt_T}_$j\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j])))+$dz[$j]*(0.5),"\"/>
    <rotation name=\"quartzCutSolRot_${opt_T}_$j\" unit=\"rad\" x=\"pi/2\" y=\"0\" z=\"pi\"/> 
</union>\n";


print def "<trd name = \"lgLogicSol_${opt_T}_$j\" z=\"$dzLg[$j]\" y1=\"",$dyLg[$j]+2*$width,"\" x1=\"",$dxLg[$j]+2*$width,"\" y2=\"",$dyPmt[$j]+2*$width,"\" x2=\"",$dxPmt[$j]+2*$width,"\" lunit= \"mm\"/>\n";

=pod
$calc=$width-(($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))*tan($refTopOpeningAngle[$j])+($dxLg[$j]+$width)*cos($lgTiltAngle[$j]);
print def "<trap name = \"refLogicSol1_${opt_T}_$j\" z=\"",$dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]),"\" theta=\"",$refTopOpeningAngle[$j]-atan((($calc-$dx[$j])*0.5)/($dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))),"\" phi=\"0\" y1=\"",$dy[$j]+2*$width,"\" x1=\"",$dx[$j]+2*$width,"\" x2=\"",$dx[$j]+2*$width,"\" alpha1=\"0\" y2=\"",$dyLg[$j]+2*$width,"\" x3=\"",$dxLg[$j]+2*$width,"\" x4=\"",$dxLg[$j]+2*$width,"\" alpha2=\"0\" aunit=\"rad\" lunit= \"mm\"/>\n";

print def "<union name=\"quartzLogicSol1_${opt_T}_$j\">
    <first ref=\"quartzRecSol_${opt_T}_$j\"/>
    <second ref=\"refLogicSol1_${opt_T}_$j\"/>
    <position name=\"quartzCutPos_${opt_T}_$j\" 
it=\"mm\" x=\"",((($dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))*tan($refTopOpeningAngle[$j])-($calc-$dx[$j])*0.5))*0.5,"\" y=\"0\" z=\"",($dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))*(0.5)+$dz[$j]*(0.5),"\"/>
    <rotation name=\"quartzCutRot_${opt_T}_$j\" unit=\"rad\" x=\"0\" y=\"0\" z=\"0\"/> 
</union>\n";
=cut


print def "<arb8 name=\"refLogicSol1_${opt_T}_$j\" v1x=\"",$dx[$j]*(0.5)+$width,"\" v1y=\"",$dy[$j]*(0.5)+$width,"\" v4x=\"",$dx[$j]*(-0.5)-$width,"\" v4y=\"",$dy[$j]*(0.5)+$width,"\" v3x=\"",$dx[$j]*(-0.5)-$width,"\" v3y=\"",$dy[$j]*(-0.5)-$width,"\" v2x=\"",$dx[$j]*(0.5)+$width,"\" v2y=\"",$dy[$j]*(-0.5)-$width,"\"   v5x=\"",$dx[$j]*(0.5)+$width+($dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))*tan($refTopOpeningAngle[$j]),"\" v5y=\"",$dyLg[$j]*0.5+$width,"\" v8x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j])-($dxLg[$j]+$width)*cos($lgTiltAngle[$j]),"\" v8y=\"",$dyLg[$j]*(0.5)+$width,"\" v7x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j])-($dxLg[$j]+$width)*cos($lgTiltAngle[$j]),"\" v7y=\"",$dyLg[$j]*(-0.5)-$width," \" v6x=\"",$dx[$j]*(0.5)+$width+($dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))*tan($refTopOpeningAngle[$j]),"\" v6y=\"",$dyLg[$j]*(-0.5)-$width,"\" dz=\"",($dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))*(0.5),"\" lunit= \"mm\"/>\n";


print def "<union name=\"quartzLogicSol1_${opt_T}_$j\">
    <first ref=\"quartzRecSol_${opt_T}_$j\"/>
    <second ref=\"refLogicSol1_${opt_T}_$j\"/>
    <position name=\"quartzCutPos_${opt_T}_$j\" 
it=\"mm\" x=\"",0,"\" y=\"0\" z=\"",($dzRef[$j]-($dxLg[$j]+$width)*sin($lgTiltAngle[$j]))*(0.5)+$dz[$j]*(0.5),"\"/>
    <rotation name=\"quartzCutRot_${opt_T}_$j\" unit=\"rad\" x=\"0\" y=\"0\" z=\"0\"/> 
</union>\n";


print def "<union name=\"quartzLogicSol_${opt_T}_$j\">
    <first ref=\"quartzLogicSol1_${opt_T}_$j\"/>
    <second ref=\"lgLogicSol_${opt_T}_$j\"/>
   <position name=\"lgLogicSolPos_${opt_T}_$j\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-$dzLg[$j]*0.5*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+$dzLg[$j]*0.5*cos($lgTiltAngle[$j]),"\"/>
    <rotation name=\"lgLogicSolRot_${opt_T}_$j\" unit=\"rad\" x=\"0\" y=\"",$lgTiltAngle[$j]*(-1),"\" z=\"0\"/> 
</union>\n";



=pod

print def "<trap name = \"refSol_${opt_T}_$j\" z=\"$dzRef[$j]\" theta=\"",atan((($dzRef[$j]*tan($refTopOpeningAngle[$j])-($dxLg[$j]-$dx[$j])*0.5))/$dzRef[$j]),"\" phi=\"0\" y1=\"$dy[$j]\" x1=\"$dx[$j]\" x2=\"$dx[$j]\" alpha1=\"0\"
y2=\"$dyLg[$j]\" x3=\"$dxLg[$j]\" x4=\"$dxLg[$j]\" alpha2=\"0\" aunit=\"rad\" lunit= \"mm\"/>\n";
  
 
print def "<subtraction name =\"refSolSkin_${opt_T}_$j\">
	<first ref=\"refLogicSol_${opt_T}_$j\"/> 
	<second ref=\"refSol_${opt_T}_$j\"/> 
	<position unit=\"mm\" name=\"quartzCutPos1_${opt_T}_$j\" x=\"",0,"\" y=\"0\" z=\"",0,"\"\/>
        <rotation unit=\"rad\" name=\"quartzCutRot1_${opt_T}_$j\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";

print def "<subtraction name =\"refSol1_${opt_T}_$j\">
	<first ref=\"refSol_${opt_T}_$j\"/> 
	<second ref=\"quartzCutSol_${opt_T}_$j\"/> 
	<position unit=\"mm\" name=\"quartzCut_${opt_T}_$j\" x=\"",(($dzRef[$j]*tan($refTopOpeningAngle[$j])-($dxLg[$j]-$dx[$j])*0.5))*(-0.5),"\" y=\"0\" z=\"",$dzRef[$j]*(-0.5)+$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j]))),"\"\/>
        <rotation unit=\"rad\" name=\"quartzCut_${opt_T}_$j\" x=\"pi/2\" y=\"0\" z=\"pi\"/>
</subtraction>\n\n";
=cut


print def "<trd name = \"lgSol_${opt_T}_$j\" z=\"$dzLg[$j]\" y1=\"$dyLg[$j]\" x1=\"$dxLg[$j]\" y2=\"$dyPmt[$j]\" x2=\"$dxPmt[$j]\" lunit= \"mm\"/>\n";

print def "<subtraction name =\"lgSolSkin_${opt_T}_$j\">
	<first ref=\"lgLogicSol_${opt_T}_$j\"/> 
	<second ref=\"lgSol_${opt_T}_$j\"/> 
	<position unit=\"mm\" name=\"quartzCut_${opt_T}_$j\" x=\"0\" y=\"0\" z=\"",0,"\"\/>
        <rotation unit=\"rad\" name=\"quartzCut_${opt_T}_$j\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";



}

print def "\n</solids>";
close(def) or warn "close failed: $!";
#########################################


### Start Structure
open(def, ">", "detector_${opt_T}.gdml") or die "cannot open > detector_${opt_T}.gdml: $!";
print def "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n
<!DOCTYPE gdml [
	<!ENTITY materials SYSTEM \"materialsNew.xml\"> 
	<!ENTITY solids_${opt_T} SYSTEM \"solids_${opt_T}.xml\"> 
]> \n
<gdml xmlns:gdml=\"http://cern.ch/2001/Schemas/GDML\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"schema/gdml.xsd\">\n

&materials; 
&solids_${opt_T};\n
<structure>\n";



for $j(0..$i-1){


print def "<volume name=\"quartzRecVol_${opt_T}\_$j\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"quartzSol_${opt_T}\_$j\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"red\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$index[$j],"\"/>  
</volume>\n";

=pod
print def "<volume name=\"refVol_${opt_T}\_$j\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"refSol1_${opt_T}\_$j\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"green\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$index[$j],"\"/>  
</volume>\n";


print def "<volume name=\"refVolSkin_${opt_T}\_$j\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"refSolSkin_${opt_T}\_$j\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"brown\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$index[$j],"\"/>  
</volume>\n";

=cut
 
print def "<volume name=\"lgVol_${opt_T}\_$j\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"lgSol_${opt_T}\_$j\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"blue\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$index[$j],"\"/>  
</volume>\n";

print def "<volume name=\"lgVolSkin_${opt_T}\_$j\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"lgSolSkin_${opt_T}\_$j\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"brown\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$index[$j],"\"/>  
</volume>\n";


print def "<volume name=\"quartzVol_${opt_T}\_$j\">
         <materialref ref=\"Air\"/>
         <solidref ref=\"quartzLogicSol_${opt_T}\_$j\"/> 
         <physvol name=\"quartzRec_${opt_T}_$j\">
			<volumeref ref=\"quartzRecVol_${opt_T}_$j\"/>
			<position name=\"detectorPos_${opt_T}_$j\" unit=\"mm\" x=\"0\" y=\"0\" z=\"0\"/>
			<rotation name=\"detectorRot_${opt_T}_$j\" unit=\"rad\" x=\"",0,"\" y=\"0\" z=\"0\"/>
</physvol> \n
        <physvol name=\"lg_${opt_T}_$j\">
			<volumeref ref=\"lgVol_${opt_T}_$j\"/>
			<position name=\"detectorPos_${opt_T}_$j\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-$dzLg[$j]*0.5*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+$dzLg[$j]*0.5*cos($lgTiltAngle[$j]),"\"/>
			<rotation name=\"detectorRot_${opt_T}_$j\" unit=\"rad\" x=\"",0,"\" y=\"",$lgTiltAngle[$j],"\" z=\"",0,"\"/>
</physvol> \n
      <physvol name=\"lgSkin_${opt_T}_$j\">
			<volumeref ref=\"lgVolSkin_${opt_T}_$j\"/>
			<position name=\"detectorPos_${opt_T}_$j\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-$dzLg[$j]*0.5*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+$dzLg[$j]*0.5*cos($lgTiltAngle[$j]),"\"/>
			<rotation name=\"detectorRot_${opt_T}_$j\" unit=\"rad\" x=\"",0,"\" y=\"",$lgTiltAngle[$j],"\" z=\"",0,"\"/>
</physvol> \n

</volume>\n";


}
print def "<volume name=\"logicMotherVol_${opt_T}\"> 
	<materialref ref=\"Air\"/>
	<solidref ref=\"logicMotherSol_${opt_T}\"/>\n";
for $j(0..$i-1){
print def "<physvol name=\"detector_${opt_T}_$j\">
			<volumeref ref=\"quartzVol_${opt_T}_$j\"/>
			<position name=\"detectorPos_${opt_T}_$j\" unit=\"mm\" x=\"$x[$j]\" y=\"$y[$j]\" z=\"$z[$j]\"/>
			<rotation name=\"detectorRot_${opt_T}_$j\" unit=\"rad\" x=\"",$rx[$j],"\" y=\"$ry[$j]\" z=\"$rz[$j]\"/>
</physvol> \n";
}
print def "</volume>";


print def "\n</structure>\n\n";


# end detector #

print def "<setup name=\"logicMother_${opt_T}\" version=\"1.0\">
	<world ref=\"logicMotherVol_${opt_T}\"/>
</setup>\n
</gdml>";

close(def) or warn "close failed: $!";

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };




