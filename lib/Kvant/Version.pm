package Kvant::Version;

sub new {
	my ($class, %params) = @_;

	open($fileVersion, $params{"fileVersion"});	
	
	my $self = bless(
		{
			"fileVersion"	=>	$fileVersion,
		},
		$class);
	
	return($self);
}

sub readBlock {
	my ($self, %params) = @_;
	
	seek($self->{"fileVersion"}, ($params{"block"} * 0x4000 + $params{"offset"}) * 2, 0);
	my @data;
	for (my $c = 1; $c <= $params{"length"}; $c++) {
		read($self->{"fileVersion"}, my $b1, 1);
		read($self->{"fileVersion"}, my $b2, 1);
		push(@data, hex(sprintf("%02x%02x", ord($b2), ord($b1))));
	}
	
	return(@data);
}

sub getRoutes {
	my ($self) = @_;
	
	my %routes;
	
	my @prefixIndexes = $self->readBlock(
			"block"		=>	0x00,
			"offset"	=>	0x6c00,
			"length"	=>	0x32,
		);
	
	my @prefixChars = $self->readBlock(
			"block"		=>	0x00,
			"offset"	=>	0x6c32,
			"length"	=>	0xc8,
		);
		
	my @prefixIndexesExt = $self->readBlock(
			"block"		=>	0x00,
			"offset"	=>	0x6d50,
			"length"	=>	0x140,
		);
		
	sub getRoute {
		my ($prefix, $index) = @_;
		my %route;
				
		my $cct = $prefixChars[$index * 2] & 0x000f;
		
		if ($cct == 0x00) {
			my $prefixIndexExt = $prefixChars[$index * 2 + 1] - 0x6d50;
			my $prefixIndex;

			for (my $c = 0; $c <= 9; $c++) {
				if ($c % 2 == 0) {
					$prefixIndex = $prefixIndexesExt[$prefixIndexExt + int($c / 2)] & 0xff;
				} else {
					$prefixIndex = $prefixIndexesExt[$prefixIndexExt + int($c / 2)] >> 0x08;
				}
			
				if ($prefixIndex == 0x00) {
					next;
				}
				
				%route = (%route, getRoute($prefix.$c, $prefixIndex));
			}
		} else {
			$route{$prefix}{"index"} = $index;
			$route{$prefix}{"cct"} = $cct;
			$route{$prefix}{"minnum"} = ($prefixChars[$index * 2] & 0x03e0) >> 0x05;
			
			if ($cct == 0x02) {
				$route{$prefix}{"cctdescr"} = "Internal";
			} elsif ($cct == 0x03) {
				$route{$prefix}{"cctdescr"} = "Group";
			} elsif ($cct == 0x05) {
				$route{$prefix}{"cctdescr"} = "Local";
				$route{$prefix}{"direction"} = ($prefixChars[$index * 2] & 0xfc00) >> 0xa;
			} elsif ($cct == 0x06) {
				$route{$prefix}{"cctdescr"} = "Special";
				$route{$prefix}{"direction"} = ($prefixChars[$index * 2] & 0xfc00) >> 0xa;
			} elsif ($cct == 0x08) {
				$route{$prefix}{"cctdescr"} = "Zone";
				$route{$prefix}{"direction"} = ($prefixChars[$index * 2] & 0xfc00) >> 0xa;
			} elsif ($cct == 0x09) {
				$route{$prefix}{"cctdescr"} = "National";
				$route{$prefix}{"direction"} = ($prefixChars[$index * 2] & 0xfc00) >> 0xa;
			} elsif ($cct == 0x0d) {
				$route{$prefix}{"maxnum"} = ($prefixChars[$index * 2 + 1] & 0xffe0) >> 0x05;
				$route{$prefix}{"cctdescr"} = "International";
				$route{$prefix}{"direction"} = ($prefixChars[$index * 2] & 0xfc00) >> 0xa;
			} else {
				$route{$prefix}{"cctdescr"} = "Unknown";
			}
		}
		
		return(%route);
	}

	for (my $c = 0; $c <= 99; $c++) {
		my $prefixIndex;
		if ($c % 2 == 0) {
			$prefixIndex = $prefixIndexes[int($c / 2)] & 0xff;
		} else {
			$prefixIndex = $prefixIndexes[int($c / 2)] >> 0x08;
		}
		
		if ($prefixIndex == 0x00) {
			next();
		}
		
		my %route = getRoute(sprintf("%02d", $c), $prefixIndex);
		%routes = (%routes, %route);
	}
	
	return(%routes);
}

sub getCOS {
	my ($self) = @_;
	
	my %coss;
	
	my @cosList = $self->readBlock(
			"block"		=>	0x00,
			"offset"	=>	0x6e00,
			"length"	=>	0x08,
		);
		
	for (my $c = 0; $c <= scalar(@cosList) - 1; $c++) {
		my $tol = ($cosList[$c] & 0xf000) >> 0xc;
		if ($tol == 0x0) {
			$coss{$c}{"tol"} = "Individual";
		} elsif ($tol == 0x1) {
			$coss{$c}{"tol"} = "Remote";
		} elsif ($tol == 0x2
					or $tol == 0x3
					or $tol == 0x4) {
			$coss{$c}{"tol"} = "Payphone";
		} elsif ($tol == 0xf) {
			$coss{$c}{"tol"} = "Disabled";
		} else {
			$coss{$c}{"tol"} = "Unknown";
		}
		
		$coss{$c}{"rfar"} = $cosList[$c] & 0x1;
		$coss{$c}{"rout"} = ($cosList[$c] & 0x2) >> 0x1;
		$coss{$c}{"rspec"} = ($cosList[$c] & 0x4) >> 0x2;
		$coss{$c}{"cid"} = ($cosList[$c] & 0x8) >> 0x3;
		$coss{$c}{"transfer"} = ($cosList[$c] & 0x100) >> 0x8;
	}
	
	return(%coss);
}

sub getACOS {
	my ($self) = @_;
	
	my %acoss;
	
	my @acosList = $self->readBlock(
			"block"		=>	0x00,
			"offset"	=>	0x6f60,
			"length"	=>	0x20,
		);
		
	for (my $c = 0; $c <= scalar(@acosList) - 1; $c += 2) {
		my $acos = int($c / 2);
		my $tol = ($acosList[$acos] & 0xf000) >> 0xc;
		if ($tol == 0x0) {
			$acoss{$acos}{"tol"} = "Individual";
		} elsif ($tol == 0x1) {
			$acoss{$acos}{"tol"} = "Remote";
		} elsif ($tol == 0x2
					or $tol == 0x3
					or $tol == 0x4) {
			$acoss{$acos}{"tol"} = "Payphone";
		} elsif ($tol == 0xf) {
			$acoss{$acos}{"tol"} = "Disabled";
		} else {
			$acoss{$acos}{"tol"} = "Unknown";
		}
		
		$acoss{$acos}{"rfar"} = $acosList[$acos] & 0x1;
		$acoss{$acos}{"rout"} = ($acosList[$acos] & 0x2) >> 0x1;
		$acoss{$acos}{"rspec"} = ($acosList[$acos] & 0x4) >> 0x2;
		$acoss{$acos}{"cid"} = ($acosList[$acos] & 0x8) >> 0x3;
		$acoss{$acos}{"transfer"} = ($acosList[$acos] & 0x100) >> 0x8;
		$acoss{$acos}{"forwbusy"} = ($acosList[$acos + 1] & 0x8) >> 0x3;
		$acoss{$acos}{"forward"} = ($acosList[$acos + 1] & 0x20) >> 0x5;
		$acoss{$acos}{"forwnoans"} = ($acosList[$acos + 1] & 0x4000) >> 0xe;
	}
	
	return(%acoss);
}

sub getStations {
	my ($self, %params) = @_;

	my %stations;
	
	my @tableNH = $self->readBlock(
			"block"		=>	0x00,
			"offset"	=>	0x6e10,
			"length"	=>	0x28,
		);
		
	my @tableHG = $self->readBlock(
			"block"		=>	0x07,
			"offset"	=>	0x0,
			"length"	=>	0x800,
		);
		
	my @ccStage1 = $self->readBlock(
			"block"		=>	0x07,
			"offset"	=>	0x1000,
			"length"	=>	0x7ff,
		);
		
	for (my $c = 0; $c <= 31; $c++) {
		my $p7 = ($tableNH[8 * 4 + int($c / 4)] >> (($c % 4) * 4)) & 0xf;
		my $p6 = ($tableNH[8 * 3 + int($c / 4)] >> (($c % 4) * 4)) & 0xf;
		my $p5 = ($tableNH[8 * 2 + int($c / 4)] >> (($c % 4) * 4)) & 0xf;
		my $p4 = ($tableNH[8 * 1 + int($c / 4)] >> (($c % 4) * 4)) & 0xf;
		my $p3 = ($tableNH[8 * 0 + int($c / 4)] >> (($c % 4) * 4)) & 0xf;
		
		my $prefix = $p7.$p6.$p5.$p4.$p3;
		
		if ($prefix == 0) {
			next;
		}
		
		for (my $d = 0; $d <= 99; $d++) {
			my $lc = $tableHG[$c * 99 + $d] & 0x7ff;
			my $ccn = $tableHG[$c * 99 + $d] >> 0xb;
			my $p0 = sprintf("%02d", $ccStage1[$lc] & 0x7f);

			my $statnum = $prefix.$p0;
			
			if (($params{"nbegin"} ne "" and $statnum < $params{"nbegin"})
				or ($params{"nend"} ne "" and $statnum > $params{"nend"})
				or ($params{"nbegin"} ne "" and $params{"nend"} eq "" and $statnum != $params{"nbegin"})) {
				next;
			}
			
			$stations{$statnum}{"cos"} = ($ccStage1[$lc] & 0x7000) >> 0xc;
		}
	}
	
	return(%stations);
}

1;
