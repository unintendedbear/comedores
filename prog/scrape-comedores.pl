#!/usr/bin/perl

use Web::Scraper;
use LWP::Simple qw(get);
use constant URL => 'http://comedoresugr.tcomunica.org';
my %meses = ( Enero => 1,
	     Febrero => 2,
	     Marzo => 3,
	     Abril => 4,
	     Mayo => 5,
	     Junio => 6,
	     Julio => 7,
	     Agosto => 8,
	     Septiembre => 9,
	     Octubre => 10,
	     Noviembre => 11,
	     Diciembre => 12 ) ;

use Data::Dumper;
use File::Slurp qw(read_file);
use XML::RSS;

my $file_name = shift;

my $menus = scraper {
      # Parse all LIs with the class "status", store them into a resulting
      # array 'tweets'.  We embed another scraper for each tweet.
      process "div#plato", "menus[]" => scraper {
          # And, in that array, pull in the elementy with the class
          # "entry-content", "entry-date" and the link
          process "div#diaplato", dia => 'TEXT';
          process "div#platos", "platos[]" => scraper {
	    process "div", 'plato[]' => 'TEXT';
	  }
      };
};

my $res;
my $contenido;

if ( !$file_name ) {
  $contenido = get(URL);
} else {
  $contenido = read_file( $file_name ) || die "No se puede leer $file_name\n";
}

$contenido =~ s/<br>/ o /g; #hack para días donde hay platos que elegir

$res = $menus->scrape( $contenido );

my $rss = new XML::RSS (version => '1.0');

$rss->channel(
   title        => "Menús de los comedores UGR",
   link         => URL,
   description  => "Menus",
   dc => {
     date       => '2000-08-23T07:00+00:00',
     subject    => "Menús de los comedores",
     creator    => 'osl@ugr.es',
     publisher  => 'osl@ugr.es',
     language   => 'es-es',
   },
   syn => {
     updatePeriod     => "weekly",
     updateFrequency  => "1",
     updateBase       => "1901-01-01T00:00+00:00",
   }
 );

for my $m ( @{$res->{'menus'}} ) {
  my ($foo, $mes, $dia) = split(/\s+/, $m->{'dia'});
  my $this_date = $dt = DateTime->new(
				      year       => DateTime->now()->year(),
				      month      => $meses{$mes},
				      day        => $dia,
				      hour       => 13,
				      minute     => 00,
				     );
  my $description;
  for my $p (@{$m->{'platos'}->[0]->{'plato'}} ) {
    chop $p;
    $description .= "$p;"
  }
  $rss->add_item(
		 title       => "Menú del día $dia del $mes",
		 link        => URL,
		 description => $description,
		 dc => { date => $this_date }
		);
}
print $rss->as_string;
		 


