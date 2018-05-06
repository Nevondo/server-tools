####################################################
###### Script to block abusive IP addresses.  ######
###### https://codeink.de                     ######    
####################################################

## Configuration ##
my $listUrl = "https://blocklist.codeink.de/";
my $fileName = "blocklist.tmp";
my $tmpDir = "/tmp";
my $file = "$tmpDir/$fileName";
my $logFile = "/var/log/blocklist";

## Binarys ##
my $iptables = "`which iptables`";
my $ipset = "`which ipset`";
my $grep = "`which grep`";
my $rm = "`which rm`";
my $wget = "`which wget`";

## Declaration ###
my($row, $Blocklist, $line, $check, $checkLine, $result, $output, $ipRegex, $message);
my ($added, $removed, $skipped); 

## Initialization ###
$added = 0;
$removed = 0;
$skipped = 0;

my @fileArray = ();
my @ipsetArray = ();

my %ipsetArray;
my %fileArray;
my $dateTime;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);

### Main ###
logging("Starting blocklist refresh");
&iptablesCheck();
&getFileArray();
&getIpsetArray();
&addIpsToBlocklist();
&remIpsFromBlocklist();
&cleanup();
exit;

## Functions ##

############# iptablesCheck ###############
## checks if all necessary               ##
## iptable/ipset Settings have been set  ##
###########################################
sub iptablesCheck {
    ## Do we have an BLOCKLIST/DROP Chain?
    if (`$iptables -L -n | $grep BLOCKLIST` =~ m/Chain BLOCKLIST/) {
    } else {
        $message = "Creating Chain BLOCKLIST";
        logging($message);
        `$iptables -N BLOCKLIST`;
        `$iptables -A BLOCKLIST -m limit --limit 2/min -j LOG --log-prefix "Blocklist Dropped: " --log-level 4`;
        `$iptables -A BLOCKLIST -j DROP`;
    }
    
    ## Do we have an ipset list called blocklist?
    if(`$ipset list -n | $grep blocklist` =~ m/blocklist/) {
    } else {
        `$ipset -N blocklist iphash --hashsize 4096`;
        $message = "Created ipset list blocklist";
        logging($message);
    }
    
    ## Is there an forwarded from INPUT to BLOCKLIST?
    if (`$iptables -L INPUT | $grep BLOCKLIST`=~ m/BLOCKLIST/) {
    } else {
        `$iptables -I INPUT -m set --match-set blocklist src -j BLOCKLIST`;
        $message = "Creating forward to BLOCKLIST chain";
        logging($message);
    }
}
######## END iptablesCheck ########

########## getFileArray #############
## downloads the Blocklist.txt and ##
## pushes it into an array         ##
#####################################
sub getFileArray {
    `$wget -q -O $tmpDir/$fileName $listUrl && echo "Downloaded temp file to $tmpDir/$fileName" || echo "Can not download file.... stopping"`;
    open(INFO, $file) or die("Could not open file.");
    foreach $line (<INFO>) {
        push(@fileArray, $line);
    }
    close(INFO);
    chomp(@fileArray);
    %fileArray = map {$_ => 1 } @fileArray;
}
####### END getFileArray ##########

######### getIpsetArray ##########
## runs ipset list blocklist    ##
## and pushes it into           ##
## array ipsetList              ##
##################################
sub getIpsetArray {
    $output = `$ipset list blocklist`;
    @ipsetArray = split("\n", $output);
#    %ipsetArray = map { $_ => 1} @ipsetArray;
    #remove the first 6 Elements of our Array using splice (ipset header info)
    splice @ipsetArray, 0, 6;
    %ipsetArray = map { $_ => 1} split("\n", $output);
}
##### END getIpsetArray #########

######## addIpsToBlocklist ######
## adds IPs to our blocklist   ##
#################################
sub addIpsToBlocklist {
    foreach $line (@fileArray) { 
        if (exists $ipsetArray{"$line"}) {
            $skipped++;
        } else {
            if ($line eq &isIpv4($line)) { 
                $result = `$ipset -A blocklist $line`;
                $added++;
                $message = "added $line";
                logging($message);
            } else {
                $skipped++;
            }
        }
    }
}
######## END addIpsToBlocklist ######

########## remIpsFromBlocklist ########
## remove IPs from our blocklist   ##
#####################################
sub remIpsFromBlocklist {
    foreach $line (@ipsetArray) {
        if (exists $fileArray{"$line"}) {
            $skipped++;   
        } else {
            if ($line eq &isIpv4($line)) {
                $result = `$ipset -D blocklist $line`;
                $message = "removed $line";
                logging($message);
                $removed++;
            } else {
                $skipped++;
            }
        }
    }
}
######## END remIpsFromBlocklist ########

################## cleanup ###################
#### Cleanup: move tmp file to new place #####
##############################################
sub cleanup {
    $result = `$rm $tmpDir/$fileName && echo "Deleted file $tmpDir/$fileName" || echo "Can\t delete file $tmpDir/$fileName"`;
    $message = "We added $added, removed $removed, skipped $skipped Rules";
    logging($message);
}
############### END cleanup ######################

############ isIpv4 #############
## check if given value looks  ##
## like an ipv4 ip address     ##
#################################
sub isIpv4 {
    my ($isIp) = @_;
    if ($isIp =~ m/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/) {
        return $isIp;
    } else {
        return 0;
    }
}
######### END isIpv4 ##########

###### log #######
## log $message ##
##################
sub logging {
    my ($message) = @_;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    open my $fh, ">>", $logFile
        or die "Can't open logfile: $!";
    $dateTime = sprintf("$months[$mon]  %02d %02d:%02d:%02d ", $mday,$hour,$min,$sec);
    print $fh "$dateTime $message\n";
    print "$message\n";
    close($fh);
}
#### end log #####