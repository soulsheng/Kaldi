#!/usr/bin/perl

# Guoguo Chen (guoguo@jhu.edu)
#
# Validation script for data/lang

if(@ARGV != 1) {
  die "Usage: validate_lang.pl lang_directory\n";
}

$lang = shift @ARGV;
$exit = 0;
# Checking phones.txt -------------------------------
print "Checking $lang/phones.txt ...\n";
if(-z "$lang/phones.txt") {print "--> ERROR: $lang/phones.txt is empty or not exists\n"; exit 1;}
if(!open(P, "<$lang/phones.txt")) {print "--> ERROR: fail to open $lang/phones.txt\n"; exit 1;}
$idx = 1;
%psymtab = ();
while(<P>) {
  chomp;
  my @col = split(" ", $_);
  if(@col != 2) {print "--> ERROR: expect 2 columns in $lang/phones.txt (break at line $idx)\n"; exit 1;}
  my $phone = shift @col;
  my $id = shift @col;
  $psymtab{$phone} = $id;
  $idx ++;
}
close(P);
%pint2sym = (); 
foreach(keys %psymtab) {
  if($pint2sym{$psymtab{$_}}) {print "--> ERROR: ID \"$psymtab{$_}\" duplicates\n"; exit 1;} 
  else {$pint2sym{$psymtab{$_}} = $_;}
}
print "--> $lang/phones.txt is OK\n";
print "\n";

# Check word.txt -------------------------------
print "Checking words.txt: #0 ...\n";
if(-z "$lang/words.txt") {print "--> ERROR: $lang/words.txt is empty or not exists\n"; exit 1;}
if(!open(W, "<$lang/words.txt")) {print "--> ERROR: fail to open $lang/words.txt\n"; exit 1;}
$idx = 1;
%wsymtab = ();
while(<W>) {
  chomp;
  my @col = split(" ", $_);
  if(@col != 2) {print "--> ERROR: expect 2 columns in $lang/words.txt (line $idx)\n"; exit 1;}
  $word = shift @col;
  $id = shift @col;
  $wsymtab{$word} = $id;
  $idx ++;
}
close(W);
%wint2sym = (); 
foreach(keys %wsymtab) {
  if($wint2sym{$wsymtab{$_}}) {print "--> ERROR: ID \"$wsymtab{$_}\" duplicates\n"; exit 1;} 
  else {$wint2sym{$wsymtab{$_}} = $_;}
}
if(exists $wsymtab{"#0"}) {
  print "--> $lang/words.txt has \"#0\"\n";
  print "--> $lang/words.txt is OK\n";
} else {print "--> ERROR: $lang/words.txt doesn't have \"#0\"\n"; $exit = 1;}
print "\n";

# Checking phones/* -------------------------------
sub check_txt_int_csl {
  my ($cat, $symtab) = @_;
  print "Checking $cat.\{txt, int, csl\} ...\n";
  if(-z "$cat.txt") {$exit = 1; return print "--> ERROR: $cat.txt is empty or not exists\n";}
  if(-z "$cat.int") {$exit = 1; return print "--> ERROR: $cat.int is empty or not exists\n";}
  if(-z "$cat.csl") {$exit = 1; return print "--> ERROR: $cat.csl is empty or not exists\n";}
  if(!open(TXT, "<$cat.txt")) {$exit = 1; return print "--> ERROR: fail to open $cat.txt\n";}
  if(!open(INT, "<$cat.int")) {$exit = 1; return print "--> ERROR: fail to open $cat.int\n";}
  if(!open(CSL, "<$cat.csl")) {$exit = 1; return print "--> ERROR: fail to open $cat.csl\n";}

  $idx1 = 1;
  while(<TXT>) {
    chomp;
    my @col = split(" ", $_);
    if(@col != 1) {$exit = 1; return print "--> ERROR: expect 1 column in $cat.txt (break at line $idx1)\n";}
    $entry[$idx1] = shift @col;
    $idx1 ++;
  }
  close(TXT); $idx1 --;
  print "--> $idx1 entry/entries in $cat.txt\n";

  $idx2 = 1;
  while(<INT>) {
    chomp;
    my @col = split(" ", $_);
    if(@col != 1) {$exit = 1; return print "--> ERROR: expect 1 column in $cat.int (break at line $idx2)\n";}
    if($symtab->{$entry[$idx2]} ne shift @col) {$exit = 1; return print "--> ERROR: $cat.int doesn't correspond to $cat.txt (break at line $idx2)\n";}
    $idx2 ++;
  }
  close(INT); $idx2 --;
  if($idx1 != $idx2) {$exit = 1; return print "--> ERROR: $cat.int doesn't correspond to $cat.txt (break at line ", $idx2+1, ")\n";}
  print "--> $cat.int corresponds to $cat.txt\n";

  $idx3 = 1;
  while(<CSL>) {
    chomp;
    my @col = split(":", $_);
    if(@col != $idx1) {$exit = 1; return print "--> ERROR: expect $idx1 block/blocks in $cat.csl (break at line $idx3)\n";}
    foreach(1 .. $idx1) {
      if($symtab->{$entry[$_]} ne @col[$_-1]) {$exit = 1; return print "--> ERROR: $cat.csl doesn't correspond to $cat.txt (break at line $idx3, block $_)\n";}
    }
    $idx3 ++;
  }
  close(CSL); $idx3 --;
  if($idx3 != 1) {$exit = 1; return print "--> ERROR: expect 1 row in $cat.csl (break at line ", $idx3+1, ")\n";}
  print "--> $cat.csl corresponds to $cat.txt\n";

  return print "--> $cat.\{txt, int, csl\} are OK\n";
}

sub check_txt_int {
  my ($cat, $symtab) = @_;
  print "Checking $cat.\{txt, int\} ...\n";
  if(-z "$cat.txt") {$exit = 1; return print "--> ERROR: $cat.txt is empty or not exists\n";}
  if(-z "$cat.int") {$exit = 1; return print "--> ERROR: $cat.int is empty or not exists\n";}
  if(!open(TXT, "<$cat.txt")) {$exit = 1; return print "--> ERROR: fail to open $cat.txt\n";}
  if(!open(INT, "<$cat.int")) {$exit = 1; return print "--> ERROR: fail to open $cat.int\n";}

  $idx1 = 1;
  while(<TXT>) {
    chomp;
    s/^(shared|not-shared) (split|not-split) //g;
    s/ nonword$//g;
    s/ begin$//g;
    s/ end$//g;
    s/ internal$//g;
    s/ singleton$//g;
    $entry[$idx1] = $_;
    $idx1 ++; 
  }
  close(TXT); $idx1 --;
  print "--> $idx1 entry/entries in $cat.txt\n";

  $idx2 = 1;
  while(<INT>) {
    chomp;
    s/^(shared|not-shared) (split|not-split) //g;
    s/ nonword$//g;
    s/ begin$//g;
    s/ end$//g;
    s/ internal$//g;
    s/ singleton$//g;
    my @col = split(" ", $_);
    @set = split(" ", $entry[$idx2]);
    if(@set != @col) {$exit = 1; return print "--> ERROR: $cat.int doesn't correspond to $cat.txt (break at line $idx2)\n";}
    foreach(0 .. @set-1) {
      if($symtab->{@set[$_]} ne @col[$_]) {$exit = 1; return print "--> ERROR: $cat.int doesn't correspond to $cat.txt (break at line $idx2, block " ,$_+1, ")\n";}
    }
    $idx2 ++;
  }
  close(INT); $idx2 --;
  if($idx1 != $idx2) {$exit = 1; return print "--> ERROR: $cat.int doesn't correspond to $cat.txt (break at line ", $idx2+1, ")\n";}
  print "--> $cat.int corresponds to $cat.txt\n";

  return print "--> $cat.\{txt, int\} are OK\n";
}

@list1 = ("context_indep", "disambig", "nonsilence", "silence", "optional_silence");
@list2 = ("extra_questions", "roots", "sets");
foreach(@list1) {
  check_txt_int_csl("$lang/phones/$_", \%psymtab); print "\n";
}
foreach(@list2) {
  check_txt_int("$lang/phones/$_", \%psymtab); print "\n";
}
if(-e "$lang/phones/word_boundary.txt") {
  check_txt_int("$lang/phones/word_boundary", \%psymtab); print "\n";
}

# Check disjoint and summation -------------------------------
sub intersect {
  my ($a, $b) = @_;
  @itset = ();
  %itset = ();
  foreach(keys %$a) {
    if(exists $b->{$_} and !$itset{$_}) {
      push(@itset, $_);
      $itset{$_} = 1;
    }
  }
  return @itset;
}

sub check_disjoint {
  print "Checking disjoint: silence.txt, nosilenct.txt, disambig.txt ...\n";
  if(!open(S, "<$lang/phones/silence.txt"))    {$exit = 1; return print "--> ERROR: fail to open $lang/phones/silence.txt\n";}
  if(!open(N, "<$lang/phones/nonsilence.txt")) {$exit = 1; return print "--> ERROR: fail to open $lang/phones/nonsilence.txt\n";}
  if(!open(D, "<$lang/phones/disambig.txt"))   {$exit = 1; return print "--> ERROR: fail to open $lang/phones/disambig.txt\n";}

  $idx = 1;
  while(<S>) {
    chomp;
    my @col = split(" ", $_);
    $phone = shift @col;
    if($silence{$phone}) {$exit = 1; print "--> ERROR: phone \"$phone\" duplicates in $lang/phones/silence.txt (line $idx)\n";}
    $silence{$phone} = 1;
    push(@silence, $phone);
    $idx ++;
  }
  close(S);

  $idx = 1; 
  while(<N>) {
    chomp;
    my @col = split(" ", $_);
    $phone = shift @col;
    if($nonsilence{$phone}) {$exit = 1; print "--> ERROR: phone \"$phone\" duplicates in $lang/phones/nonsilence.txt (line $idx)\n";}
    $nonsilence{$phone} = 1;
    push(@nonsilence, $phone);
    $idx ++;
  }
  close(N);

  $idx = 1;
  while(<D>) {
    chomp;
    my @col = split(" ", $_);
    $phone = shift @col;
    if($disambig{$phone}) {$exit = 1; print "--> ERROR: phone \"$phone\" duplicates in $lang/phones/disambig.txt (line $idx)\n";}
    $disambig{$phone} = 1;
    $idx ++;
  }
  close(D);

  my @itsect1 = intersect(\%silence, \%nonsilence);
  my @itsect2 = intersect(\%silence, \%disambig);
  my @itsect3 = intersect(\%disambig, \%nonsilence);

  $success = 1;
  if(@itsect1 != 0) {
    $success = 0;
    $exit = 1; print "--> ERROR: silence.txt and nonsilence.txt have intersection -- ";
    foreach(@itsect1) {
      print $_, " ";
    }
    print "\n";
  } else {print "--> silence.txt and nonsilence.txt are disjoint\n";}

  if(@itsect2 != 0) {
    $success = 0;
    $exit = 1; print "--> ERROR: silence.txt and disambig.txt have intersection -- ";
    foreach(@itsect2) {
      print $_, " ";
    }
    print "\n";
  } else {print "--> silence.txt and disambig.txt are disjoint\n";}

  if(@itsect3 != 0) {
    $success = 0;
    $exit = 1; print "--> ERROR: disambig.txt and nonsilence.txt have intersection -- ";
    foreach(@itsect1) {
      print $_, " ";
    }
    print "\n";
  } else {print "--> disambig.txt and nonsilence.txt are disjoint\n";}

  $success == 0 || print "--> disjoint property is OK\n";
  return;
}

sub check_summation {
  print "Checking sumation: silence.txt, nonsilence.txt, disambig.txt ...\n";
  if(scalar(keys %silence) == 0)      {$exit = 1; return print "--> ERROR: $lang/phones/silence.txt is empty or not exists\n";}
  if(scalar(keys %nonsilence) == 0)   {$exit = 1; return print "--> ERROR: $lang/phones/nonsilence.txt is empty or not exists\n";}
  if(scalar(keys %disambig) == 0)     {$exit = 1; return print "--> ERROR: $lang/phones/disambig.txt is empty or not exists\n";}

  %sum = (%silence, %nonsilence, %disambig);
  $sum{"<eps>"} = 1;

  my @itset = intersect(\%sum, \%psymtab);
  my @key1 = keys %sum;
  my @key2 = keys %psymtab;
  my %itset = (); foreach(@itset) {$itset{$_} = 1;}
  if(@itset < @key1) {
    $exit = 1; print "--> ERROR: phones in silence.txt, nonsilence.txt, disambig.txt but not in phones.txt -- ";
    foreach(@key1) {
      if(!$itset{$_}) {print "$_ ";}
    }
    print "\n";
  }

  if(@itset < @key2) {
    $exit = 1; print "--> ERROR: phones in phones.txt but not in silence.txt, nonsilence.txt, disambig.txt -- ";
    foreach(@key2) {
      if(!$itset{$_}) {print "$_ ";}
    }
    print "\n";
  }

  if(@itset == @key1 and @itset == @key2) {
    print "--> summation property is OK\n";
  }
  return;
}

%silence = ();
@silence = ();
%nonsilence = ();
@nonsilence = ();
%disambig = ();
check_disjoint; print "\n";
check_summation; print "\n";

# Checking optional_silence.txt -------------------------------
print "Checking optional_silence.txt ...\n";
$idx = 1;
$success = 1;
if(-z "$lang/phones/optional_silence.txt") {$exit = 1; $success = 0; print "--> ERROR: $lang/phones/optional_silence.txt is empty or not exists\n";}
if(!open(OS, "<$lang/phones/optional_silence.txt")) {$exit = 1; $success = 0; print "--> ERROR: fail to open $lang/phones/optional_silence.txt\n";}
print "--> reading $lang/phones/optional_silence.txt\n";
while(<OS>) {
  chomp;
  my @col = split(" ", $_);
  if ($idx > 1 or @col > 1) {
    $exit = 1; print "--> ERROR: only 1 phone expected in $lang/phones/optional_silence.txt\n"; $success = 0;
  } elsif (!$silence{$col[0]}) {
    $exit = 1; print "--> ERROR: phone $col[0] not found in $lang/phones/silence_phones.txt\n"; $success = 0;
  }
  $idx ++;
}
close(OS);
$success == 0 || print "--> $lang/phones/optional_silence.txt is OK\n";
print "\n";

# Check disambiguation symbols -------------------------------
print "Checking disambiguation symbols: #0 and #1\n";
if(scalar(keys %disambig) == 0) {$exit = 1; print "--> ERROR: $lang/phones/disambig.txt is empty or not exists\n";}
if(exists $disambig{"#0"} and exists $disambig{"#1"}) {
  print "--> $lang/phones/disambig.txt has \"#0\" and \"#1\"\n";
  print "--> $lang/phones/disambig.txt is OK\n\n";
} else {
  $exit = 1; print "--> ERROR: $lang/phones/disambig.txt doesn't have \"#0\" or \"#1\"\n";
}


# Check topo -------------------------------
print "Checking topo ...\n";
if(-z "$lang/topo") {$exit = 1; print "--> ERROR: $lang/topo is empty or not exists\n";}
if(!open(T, "<$lang/topo")) {$exit = 1; print "--> ERROR: fail to open $lang/topo\n";}
$idx = 1;
while(<T>) {
  chomp;
  next if(m/^<.*>[ ]*$/);
  if($idx == 1) {$nonsilence_seq = $_; $idx ++;}
  if($idx == 2) {$silence_seq = $_;}
}
close(T);
if($silence_seq == 0 || $nonsilence_seq == 0) {$exit = 1; print "--> ERROR: $lang/topo doesn't have nonsilence section or silence section\n";}
@silence_seq = split(" ", $silence_seq);
@nonsilence_seq = split(" ", $nonsilence_seq);
$success1 = 1;
if(@nonsilence_seq != @nonsilence) {$exit = 1; print "--> ERROR: $lang/topo's nonsilence section doesn't correspond to nonsilence.txt\n";}
else {
  foreach(0 .. scalar(@nonsilence)-1) {
    if($psymtab{@nonsilence[$_]} ne @nonsilence_seq[$_]) {
      $exit = 1; print "--> ERROR: $lang/topo's nonsilence section doesn't correspond to nonsilence.txt\n";
      $success = 0;
    }
  }
}
$success1 != 1 || print "--> $lang/topo's nonsilence section is OK\n";
$success2 = 1;
if(@silence_seq != @silence) {$exit = 1; print "--> ERROR: $lang/topo's silence section doesn't correspond to silence.txt\n";}
else {
  foreach(0 .. scalar(@silence)-1) {
    if($psymtab{@silence[$_]} ne @silence_seq[$_]) {
      $exit = 1; print "--> ERROR: $lang/topo's silence section doesn't correspond to silence.txt\n";
      $success = 0;
    }
  }
}
$success2 != 1 || print "--> $lang/topo's silence section is OK\n";
$success1 != 1 or $success2 != 1 || print "--> $lang/topo is OK\n";
print "\n";

# Check word_boundary -------------------------------
$nonword   = "";
$begin     = "";
$end       = "";
$internal  = "";
$singleton = "";
if(-s "$lang/phones/word_boundary.txt") {
  print "Checking word_boundary.txt: silence.txt, nonsilence.txt, disambig.txt ...\n";
  if(!open (W, "<$lang/phones/word_boundary.txt")) {$exit = 1; print "--> ERROR: fail to open $lang/phones/word_boundary.txt\n";}
  $idx = 1;
  %wb = ();
  while(<W>) {
    chomp;
    my @col;
    if (m/^.*nonword$/  ) {s/ nonword//g;    @col = split(" ", $_); if (@col == 1) {$nonword   .= "$col[0] ";}}
    if (m/^.*begin$/    ) {s/ begin$//g;     @col = split(" ", $_); if (@col == 1) {$begin     .= "$col[0] ";}}
    if (m/^.*end$/      ) {s/ end$//g;       @col = split(" ", $_); if (@col == 1) {$end       .= "$col[0] ";}}
    if (m/^.*internal$/ ) {s/ internal$//g;  @col = split(" ", $_); if (@col == 1) {$internal  .= "$col[0] ";}}
    if (m/^.*singleton$/) {s/ singleton$//g; @col = split(" ", $_); if (@col == 1) {$singleton .= "$col[0] ";}}
    if(@col != 1) {$exit = 1; print "--> ERROR: expect 1 column in $lang/phones/word_boundary.txt (line $idx)\n";}
    $wb{shift @col} = 1;
    $idx ++;
  }
  close(W);

  @itset = intersect(\%disambig, \%wb);
  $success1 = 1;
  if(@itset != 0) {
    $success1 = 0;
    $exit = 1; print "--> ERROR: $lang/phones/word_boundary.txt has disambiguation symbols -- ";
    foreach(@itset) {print "$_ ";}
    print "\n";
  }
  $success1 == 0 || print "--> $lang/phones/word_boundary.txt doesn't include disambiguation symbols\n";

  %sum = (%silence, %nonsilence);
  @itset = intersect(\%sum, \%wb);
  %itset = (); foreach(@itset) {$itset{$_} = 1;}
  $success2 = 1;
  if(@itset < scalar(keys %sum)) {
    $success2 = 0;
    $exit = 1; print "--> ERROR: phones in nonsilence.txt and silence.txt but not in word_boundary.txt -- ";
    foreach(keys %sum) {
      if(!$itset{$_}) {print "$_ ";}            
    }
    print "\n";
  }
  if(@itset < scalar(keys %wb)) {
    $success2 = 0;
    $exit = 1; print "--> ERROR: phones in word_boundary.txt but not in nonsilence.txt or silence.txt -- ";
    foreach(keys %wb) {
      if(!$itset{$_}) {print "$_ ";}
    }
    print "\n";
  }
  $success2 == 0 || print "--> $lang/phones/word_boundary.txt is the union of nonsilence.txt and silence.txt\n";
  $success1 != 1 or $success2 != 1 || print "--> $lang/phones/word_boundary.txt is OK\n";


  # Check L.fst -------------------------------
  print "--> checking L.fst and L_disambig.fst...\n";
  $nonword   =~ s/ $//g;
  $nonword   =~ s/ / |/g;
  $begin     =~ s/ $//g;
  $begin     =~ s/ / |/g;
  $end       =~ s/ $//g;
  $end       =~ s/ / |/g;
  $internal  =~ s/ $//g;
  $internal  =~ s/ / |/g;
  $singleton =~ s/ $//g;
  $singleton =~ s/ / |/g;
  
  # Now handle the escape characters
  foreach $esc(("^", "\$", "(", ")", "/", "@", "[", "]", "{", "}", "?", ".", "+", "*")) {
    $tmp = "\\" . $esc;
    $nonword   =~ s/$tmp/\\$esc/g;
    $begin     =~ s/$tmp/\\$esc/g;
    $end       =~ s/$tmp/\\$esc/g;
    $internal  =~ s/$tmp/\\$esc/g;
    $singleton =~ s/$tmp/\\$esc/g;
  }

  $wlen = int(rand(100)) + 1;
  print "--> generating a $wlen words sequence\n";
  $wordseq = "";
  $sid = 0;
  foreach(1 .. $wlen) {
    $id = int(rand(scalar(%wint2sym)));
    while($wint2sym{$id} =~ m/^#[0-9]*$/ or $id == 0) {$id = int(rand(scalar(%wint2sym)));}
    $wordseq = $wordseq . "$sid ". ($sid + 1) . " $id $id 0\n";
    $sid ++;
  }
  $wordseq = $wordseq . "$sid 0";
  $phoneseq = `echo \"$wordseq" | fstcompile > tmp.fst; fstcompose $lang/L.fst tmp.fst | fstproject | fstrandgen | fstrmepsilon | fsttopsort | fstprint --isymbols=$lang/phones.txt --osymbols=$lang/phones.txt | awk '{if(NF > 2) {print \$3}}'; rm tmp.fst`;
  $phoneseq =~ s/\s/ /g;
  $phoneseq =~ m/^($nonword )*(((($begin )($internal )*($end ))|($singleton ))($nonword )*){$wlen}$/;
  if(length($2) == 0) {
    $exit = 1; print "--> ERROR: resulting phone sequence from L.fst doesn't correspond to the word sequence; check L.log.fst\n";
    open(LOG, ">L.log.fst"); print LOG $wordseq; close(LOG);
  } else {
    print "--> resulting phone sequence from L.fst corresponds to the word sequence\n";
    print "--> L.fst is OK\n";
  }

  $phoneseq = `echo \"$wordseq" | fstcompile > tmp.fst; fstcompose $lang/L_disambig.fst tmp.fst | fstproject | fstrandgen | fstrmepsilon | fsttopsort | fstprint --isymbols=$lang/phones.txt --osymbols=$lang/phones.txt | awk '{if(NF > 2) {print \$3}}'; rm tmp.fst`;
  $phoneseq =~ s/\s/ /g;
  $phoneseq =~ m/^(($nonword )(#[0-9]* )*)*(((($begin )($internal )*($end ))|($singleton ))(#[0-9]* )*(($nonword )(#[0-9]* )*)*){$wlen}$/;
  if(length($4) == 0) {
    $exit = 1; print "--> ERROR: resulting phone sequence from L_disambig.fst doesn't correspond to the word sequence; check L_disambig.log.fst\n";
    open(LOG, ">L_disambig.log.fst"); print LOG $wordseq; close(LOG);
  } else {
    print "--> resulting phone sequence from L_disambig.fst corresponds to the word sequence\n";
    print "--> L_disambig.fst is OK\n";
  }
  print "\n";
}

# Check oov -------------------------------
check_txt_int("$lang/oov", \%wsymtab); print "\n";


if ($exit == 1) {exit 1;}
