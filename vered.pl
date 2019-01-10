BEGIN {
	push(@INC, "lib");
}

use Getopt::Std;
use Term::ReadLine;
use Kvant::Version;

use formats;

my %opts;
getopts("hf:", \%opts);

if (!$opts{"f"}
	or $opts{"h"}) {
	$~ = "FORMAT_HELP";
	write();
	exit();
}

if (-f $opts{"f"}) {
	my $versionSize = (-s $opts{"f"});
	
	if ($versionSize == 393216) {
		printf("File Version size: %d bytes\n\n", $versionSize);

		my $kvantVersion = Kvant::Version->new(
				"fileVersion"	=>	$opts{"f"},
			);
	
		my $term = Term::ReadLine->new("vered");
		my $termPrompt = "> ";
		my $termOut = $term->OUT() or \*STDOUT;
		while (defined(my $termLine = $term->readline($termPrompt))) {
			if ($termLine =~ /^\s*$/) {
				next;
			}
		
			$term->addhistory($termLine);

			$termLine =~ s/(^\s*|\s*$)//g;
		
			if ($termLine eq "exit") {
				exit();
			} elsif ($termLine eq "help") {
				$~ = "FORMAT_TERM_HELP";
				write();
			} elsif ($termLine eq "routes") {
				$~ = "FORMAT_ROUTE_HEADER";
				write();
				my %routes = $kvantVersion->getRoutes();
				foreach my $key (sort(keys(%routes))) {
					$~ = "FORMAT_ROUTE";
					$route = $key;
					$route .= "*" x ($routes{$key}{"minnum"} - length($key));
					$route .= "?" x ($routes{$key}{"maxnum"} - $routes{$key}{"minnum"});
					$cctdescr = $routes{$key}{"cctdescr"};
					$direction = sprintf("%x", $routes{$key}{"direction"});
					write();
				}
			} elsif ($termLine eq "cos") {
				$~ = "FORMAT_COS_HEADER";
				write();
				my %coss = $kvantVersion->getCOS();
				foreach my $key (sort(keys(%coss))) {
					$~ = "FORMAT_COS";
					$cos = $key;
					$tol = $coss{$key}{"tol"};
					$rfar = $coss{$key}{"rfar"} ? "-" : "+";
					$rout = $coss{$key}{"rout"} ? "-" : "+";;
					$rspec = $coss{$key}{"rspec"} ? "-" : "+";
					$cid = $coss{$key}{"cid"} ? "+" : "-";
					$transfer = $coss{$key}{"transfer"} ? "+" : "-";
					write();
				}
			} elsif ($termLine eq "acos") {
				$~ = "FORMAT_ACOS_HEADER";
				write();
				my %acoss = $kvantVersion->getACOS();
				foreach my $key (sort {$a <=> $b} (keys(%acoss))) {
					$~ = "FORMAT_ACOS";
					$acos = $key;
					$tol = $acoss{$key}{"tol"};
					$rfar = $acoss{$key}{"rfar"} ? "-" : "+";
					$rout = $acoss{$key}{"rout"} ? "-" : "+";;
					$rspec = $acoss{$key}{"rspec"} ? "-" : "+";
					$cid = $acoss{$key}{"cid"} ? "+" : "-";
					$transfer = $acoss{$key}{"transfer"} ? "+" : "-";
					$forwbusy = $acoss{$key}{"forwbusy"} ? "+" : "-";
					$forward = $acoss{$key}{"forward"} ? "+" : "-";
					$forwnoans = $acoss{$key}{"forwnoans"} ? "+" : "-";
					write();
				}
			} elsif ($termLine =~ /stations\s*(\d*)-?(\d*)/) {
				my ($nbegin, $nend) = ($1, $2);
			
				$~ = "FORMAT_STATIONS_HEADER";
				write();
				$~ = "FORMAT_STATIONS";
				my %stations = $kvantVersion->getStations(
						"nbegin"	=>	$nbegin,
						"nend"		=>	$nend,
					);
				foreach my $key (sort {$a <=> $b} (keys(%stations))) {
					$station = $key;
					$cos = $stations{$key}{"cos"};
					write();
				}
			} else {
				printf("Unknown command\n");
			}
		}
	} else {
		printf("File Version with %d bytes not supported\n", $versionSize);
	}
} else {
	printf("No such file %s\n", $opts{"f"});
}
