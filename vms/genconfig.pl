#!/usr/bin/perl
# Habit . . .
#
# Extract info from Config.VMS, and add extra data here, to generate Config.sh
# Edit the static information after __END__ to reflect your site and options
# that went into your perl binary.  In addition, values which change from run
# to run may be supplied on the command line as key=val pairs.
#
# Rev. 13-Dec-1995  Charles Bailey  bailey@genetics.upenn.edu
#

unshift(@INC,'lib');  # In case someone didn't define Perl_Root
                      # before the build

if ($ARGV[0] eq '-f') {
  open(ARGS,$ARGV[1]) or die "Can't read data from $ARGV[1]: $!\n";
  @ARGV = ();
  while (<ARGS>) {
    push(@ARGV,split(/\|/,$_));
  }
  close ARGS;
}

if (-f "config.vms") { $infile = "config.vms"; $outdir = "[-]"; }
elsif (-f "[.vms]config.vms") { $infile = "[.vms]config.vms"; $outdir = "[]"; }
elsif (-f "config.h") { $infile = "config.h"; $outdir = "[]";}

if ($infile) { print "Generating Config.sh from $infile . . .\n"; }
else { die <<EndOfGasp;
Can't find config.vms or config.h to read!
	Please run this script from the perl source directory or
	the VMS subdirectory in the distribution.
EndOfGasp
}
$outdir = '';
open(IN,"$infile") || die "Can't open $infile: $!\n";
open(OUT,">${outdir}Config.sh") || die "Can't open ${outdir}Config.sh: $!\n";

$time = localtime;
print OUT <<EndOfIntro;
# This file generated by GenConfig.pl on a VMS system.
# Input obtained from:
#     $infile
#     $0
# Time: $time

package='perl5'
CONFIG='true'
cf_time='$time'
osname='VMS'
ld='Link'
lddlflags='/Share'
ranlib=''
ar=''
eunicefix=':'
hint='none'
hintfile=''
intsize='4'
alignbytes='8'
shrplib='define'
usemymalloc='n'
spitshell='write sys\$output '
EndOfIntro

$cf_by = (getpwuid($<))[0];
print OUT "cf_by='$cf_by'\n";

$hw_model = `Write Sys\$Output F\$GetSyi("HW_MODEL")`;
chomp $hw_model;
if ($hw_model > 1024) {
  print OUT "arch='VMS_AXP'\n";
  print OUT "archname='VMS_AXP'\n";
  $archsufx = "AXP";
}
else {
  print OUT "arch='VMS_VAX'\n";
  print OUT "archname='VMS_VAX'\n";
  $archsufx = 'VAX';
}
$osvers = `Write Sys\$Output F\$GetSyi("VERSION")`;
$osvers =~ s/^V?(\S+)\s*\n?$/$1/;
print OUT "osvers='$osvers'\n";
foreach (@ARGV) {
  ($key,$val) = split('=',$_,2);
  if ($key eq 'cc') {  # Figure out which C compiler we're using
    my($cc,$ccflags) = split('/',$val,2);
    my($d_attr);
    $ccflags = "/$ccflags";
    if ($ccflags =~s!/DECC!!ig) { 
      $cc .= '/DECC';
      $cctype = 'decc';
      $d_attr = 'undef';
    }
    elsif ($ccflags =~s!/VAXC!!ig) {
      $cc .= '/VAXC';
      $cctype = 'vaxc';
      $d_attr = 'undef';
    }
    elsif (`$val/NoObject/NoList _nla0:/Version` =~ /GNU/) {
      $cctype = 'gcc';
      $d_attr = 'define';
    }
    elsif ($archsufx eq 'VAX' &&
           `$val/NoObject/NoList /prefix=all _nla0:` =~ /IVQUAL/) {
      $cctype = 'vaxc';
      $d_attr = 'undef';
    }
    else {
      $cctype = 'decc';
      $d_attr = 'undef';
    }
    print OUT "vms_cc_type='$cctype'\n";
    print OUT "d_attribut='$d_attr'\n";
    print OUT "cc='$cc'\n";
    if ( ($cctype eq 'decc' and $archsufx eq 'VAX') || $cctype eq 'gcc') {
      # gcc and DECC for VAX requires filename in /object qualifier, so we
      # have to remove it here.  Alas, this means we lose the user's
      # object file suffix if it's not .obj.
      $ccflags =~ s#/obj(?:ect)?=[^/\s]+##i;
    }
    print OUT "ccflags='$ccflags'\n";
    $dosock = ($ccflags =~ m!/DEF[^/]+VMS_DO_SOCKETS!i and
               $ccflags !~ m!/UND[^/]+VMS_DO_SOCKETS!i);
    next;
  }
  print OUT "$key=\'$val\'\n";
}

# Are there any other logicals which TCP/IP stacks use for the host name?
$myname = $ENV{'ARPANET_HOST_NAME'}  || $ENV{'INTERNET_HOST_NAME'} ||
          $ENV{'MULTINET_HOST_NAME'} || $ENV{'UCX$INET_HOST'}      ||
          $ENV{'TCPWARE_DOMAINNAME'} || $ENV{'NEWS_ADDRESS'};
if (!$myname) {
  ($myname) = `hostname` =~ /^(\S+)/;
  if ($myname =~ /IVVERB/) {
    warn "Can't determine TCP/IP hostname" if $dosock;
    $myname = '';
  }
}
$myname = $ENV{'SYS$NODE'} unless $myname;
($myhostname,$mydomain) = split(/\./,$myname,2);
print OUT "myhostname='$myhostname'\n" if $myhostname;
if ($mydomain) {
  print OUT "mydomain='.$mydomain'\n";
  print OUT "perladmin='$cf_by\@$myhostname.$mydomain'\n";
  print OUT "cf_email='$cf_by\@$myhostname.$mydomain'\n";
}
else {
  print OUT "perladmin='$cf_by'\n";
  print OUT "cf_email='$cf_by'\n";
}
chomp($hwname = `Write Sys\$Output F\$GetSyi("HW_NAME")`);
$hwname = $archsufx if $hwname =~ /IVKEYW/;  # *really* old VMS version
print OUT "myuname='VMS $myname $osvers $hwname'\n";

while (<IN>) {  # roll through the comment header in Config.VMS
  last if /config-start/;
}

while (<IN>) {
  chop;
  while (/\\\s*$/) {  # pick up contination lines
    my $line = $_;
    $line =~ s/\\\s*$//;
    $_ = <IN>;
    s/^\s*//;
    $_ = $line . $_;
  }              
  next unless my ($blocked,$un,$token,$val) = m%^(\/\*)?\s*\#\s*(un)?def\w*\s*([A-za-z0-9]\w+)\S*\s*(.*)%;
  next if /config-skip/;
  $state = ($blocked || $un) ? 'undef' : 'define';
  $token =~ tr/A-Z/a-z/;
  $token =~ s/_exp$/exp/;  # Config.pm has 'privlibexp' etc. where config.h
                           # has 'privlib_exp' etc.
  # Fixup differences between Configure vars and config.h manifests
  # This isn't comprehensize; we fix 'em as we need 'em.
  $token = 'castneg'   if $token eq 'castnegfloat';
  $token = 'dlsymun'   if $token eq 'dlsym_needs_underscore';
  $token = 'stdstdio'  if $token eq 'use_stdio_ptr';
  $token = 'stdiobase'  if $token eq 'use_stdio_base';
  $val =~ s%/\*.*\*/\s*%%g;  $val =~ s/\s*$//;  # strip off trailing comment
  $val =~ s/^"//; $val =~ s/"$//;               # remove end quotes
  $val =~ s/","/ /g;                            # make signal list look nice
  if ($val) { print OUT "$token=\'$val\'\n"; }
  else {
    $token = "d_$token" unless $token =~ /^i_/;
    print OUT "$token='$state'\n";
  }
}
close IN;

while (<DATA>) {
  next if /^\s*#/ or /^\s*$/;
  s/#.*$//;  s/\s*$//;
  ($key,$val) = split('=',$_,2);
  print OUT "$key='$val'\n";
  eval "\$$key = '$val'";
}
# Add in some of the architecture-dependent stuff which has to be consistent
print OUT "d_vms_do_sockets=",$dosock ? "'define'\n" : "'undef'\n";
print OUT "d_has_sockets=",$dosock ? "'define'\n" : "'undef'\n";
$archlib = &VMS::Filespec::vmspath($privlib);
$installarchlib = &VMS::Filespec::vmspath($installprivlib);
$sitearch = &VMS::Filespec::vmspath($sitelib);
$archlib =~ s#\]#.VMS_$archsufx\]#;
$sitearch =~ s#\]#.VMS_$archsufx\]#;
print OUT "oldarchlib='$archlib'\n";
print OUT "oldarchlibexp='$archlib'\n";
($vers = $]) =~ tr/./_/;
$archlib =~ s#\]#.$vers\]#;
$installarchlib =~ s#\]#.VMS_$archsufx.$vers\]#;
print OUT "archlib='$archlib'\n";
print OUT "archlibexp='$archlib'\n";
print OUT "installarchlib='$installarchlib'\n";
print OUT "sitearch='$sitearch'\n";
print OUT "sitearchexp='$sitearch'\n";

if (open(OPT,"${outdir}crtl.opt")) {
  while (<OPT>) {
    next unless m#/(sha|lib)#i;
    chomp;
    if (/crtl/i || /gcclib/i) { push(@crtls,$_); }
    else                      { push(@libs,$_);  }
  }
  close OPT;
  print OUT "libs='",join(' ',@libs),"'\n";
  push(@crtls,'(DECCRTL)') if $cctype eq 'decc';
  print OUT "libc='",join(' ',@crtls),"'\n";
}
else { warn "Can't read ${outdir}crtl.opt - skipping 'libs' & 'libc'"; }

if (open(PL,"${outdir}patchlevel.h")) {
  while (<PL>) {
    next unless /PATCHLEVEL\s+(\S+)/;
    print OUT "PATCHLEVEL='$1'\n";
    last;
  }
  close PL;
}
else { warn "Can't read ${outdir}patchlevel.h - skipping 'PATCHLEVEL'"; }

# simple pager support for perldoc
if    (`most nl:` =~ /IVVERB/) {
  $pager = 'more';
  if (`more nl:` =~ /IVVERB/) { $pager = 'type/page'; }
}
else { $pager = 'most'; }
print OUT "pager='$pager'\n";

close OUT;
__END__

# This list is incomplete in comparison to what ends up in config.sh, but
# should contain the essentials.  Some of these definitions reflect
# options chosen when building perl or site-specific data; these should
# be hand-edited appropriately.  Someday, perhaps, we'll get this automated.

# The definitions in this block are constant across most systems, and
# should only rarely need to be changed.
ccdlflags=
cccdlflags=
usedl=true
dlobj=dl_vms.obj
dlsrc=dl_vms.c
so=exe
dlext=exe
libpth=/sys$share /sys$library
usevfork=false
castflags=0
signal_t=void
timetype=long
builddir=perl_root:[000000]
prefix=perl_root
installprivlib=perl_root:[lib]     # The *lib constants should match the
privlib=perl_root:[lib]            # equivalent *(?:ARCH)LIB_EXP constants
sitelib=perl_root:[lib.site_perl]  # in config.h
installbin=perl_root:[000000]
installman1dir=perl_root:[man.man1]
installman3dir=perl_root:[man.man3]
man1ext=rno
man3ext=rno
binexp=perl_root:[000000]  # should be same as installbin
useposix=false
