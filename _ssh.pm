package _ssh;{
  use strict;
  use warnings;
  use utf8;
  use lib 'libs';
  use parent "ssh";
  use constant BUFLEN => 10_0000;
  use Data::Dumper;
  use Fcntl;

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
  
  sub write {
    my($self, $folder, $data) = @_;
	my(%data);

	$self->connect() if ( $self->get('error') == 1 );

	eval{
			foreach my $filename ( keys %{$data} ) {
				my $path = $folder.$filename if defined($folder);
				$self->{log}->save('i', "write: ". $filename . "\t" . Dumper($data->{$filename})) if $self->{obj}->{'DEBUG'};
				my $fh = $self->get('ssh')->sftp->open($path, O_WRONLY | O_CREAT | O_TRUNC) || die $self->get('ssh')->die_with_error;
				print $fh $_."\r\n" for @{$data->{$filename}};
				close $fh;
			}
	};
	if($@) { $self->set('error' => 1);
			 $self->{log}->save('e', "$@");
			 $self->disconnect();
	}
  }

  sub delete {
    my($self, $folder, $filename) = @_;

	$self->connect() if ( $self->get('error') == 1 );

	eval{
			my $path = $folder.$filename if defined($folder);
			$self->{log}->save('i', "delete file: ". $path) if $self->{obj}->{'DEBUG'};
			$self->get('ssh')->sftp->unlink($path) || die $self->get('ssh')->die_with_error;
	};
	if($@) { $self->set('error' => 1);
			 $self->{log}->save('e', "$@");
			 $self->disconnect();
	}
  }
}
1;

