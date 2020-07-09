package _ssh;{
  use strict;
  use warnings;
  use utf8;
  use lib 'libs';
  use parent "ssh";
  use constant BUFLEN => 10_0000;
  use Data::Dumper;

  sub read {
    my($self, $folder) = @_;
	my(%data);

	$self->connect() if ( $self->get('error') == 1 );

	eval{
			my $dh = $self->get('ssh')->sftp->opendir($folder) || die $self->get('ssh')->die_with_error;
			while (my %entries = $dh->read) {
				print "$entries{name}\n" if $self->{obj}->{'DEBUG'};
				next if ($entries{name} =~ m/^\./);
				my $fh = $self->get('ssh')->sftp->open($folder.'/'.$entries{name}) || die $self->get('ssh')->die_with_error;
				$fh->seek(0);
				chomp(my @DATA = <$fh>);
				$data{$entries{name}} = [@DATA];
				print Dumper(\%data) if $self->{obj}->{'DEBUG'};
				close $fh;
			}
			close $dh;
	};
	if($@) { $self->set('error' => 1);
			 $self->{log}->save('e', "$@");
			 $self->disconnect();
	}
    return(\%data);
  }
}
1;

