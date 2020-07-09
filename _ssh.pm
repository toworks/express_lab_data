package _ssh;{
  use strict;
  use warnings;
  use utf8;
  use lib 'libs';
  use parent "ssh";
  use constant BUFLEN => 10_0000;
  use Data::Dumper;

  sub read_file {
    my($self, $remote_folder, $local_folder) = @_;
	my($data, $channel, $buf, %values, $timestamp, $value, $remotedate);
	
	%values = ();

	$self->connect() if ( $self->get('error') == 1 );

	eval{	$self->{obj}->{channel}->write("date -u +'%Y/%m/%d'\n") || die "cannot write to shell: $@";
			#$self->{channel}->flush || die $self->{log}->save('e', "cannot flush: $@");
			$self->{obj}->{channel}->blocking(1) || die "cannot blocking: $@";
			select(undef, undef, undef, 0.2); # sleep 50 ms
			$self->{obj}->{channel}->read($buf, BUFLEN) || die "cannot read to shell: $@";
			my $remotedate = $buf;
			chomp($remotedate);

			print $remotedate, "\n";
			$buf = undef;

 
# (a) read using SCP
#my $passwd;# = IO::Scalar->new;
#die "can't fetch /etc/passwd" unless
#my $passwd = 'tst';
# $self->get('ssh')->scp_get('tst.log', $passwd);
#$passwd->seek(0, 0);
#_read($passwd);
 
 
 my $dh = $self->get('ssh')->sftp->opendir($remote_folder)
 #my $fh = $self->get('ssh')->sftp->open('tst/tst.log')
  or $self->get('ssh')->die_with_error;
 
while (my %entries = $dh->read) {
#  print "$_\n" for keys %entries;
  print "$entries{name}\n";
  my $fh = $self->get('ssh')->sftp->open($remote_folder.'/'.$entries{name});
  print while <$fh>;

	$fh->seek(0);
 
#  open(my $fh_, '>', $entries{name}) or die "Не могу открыть файл $!";
  #print $fh_ "Мой первый отчет, сгенерированный с помощью perl\n";
  #print $fh_ $_ while <$fh>;
  my @DATA = <$fh>;
  
  $values{$entries{name}} = [@DATA];
  
 print Dumper(\%values);
#  _write($entries{name}, \@DATA);
  
#  close $fh_;
 
}


#print while <$fh>;

# (b) read a line at a time with SFTP
#my $sftp = $ssh2->sftp;
#my $file = $sftp->open('/etc/passwd') or $sftp->die_with_error;
#_read($file);

=comm
			foreach my $type (keys %{$measuring}) {
				foreach (keys %{$measuring->{$type}}) {
					#print "$measuring->{$type}->{$_}->{id_measuring} | $measuring->{$type}->{$_}->{unit} | $measuring->{$type}->{$_}->{tag}\n";
					$self->{channel}->write("tail -n 1 $self->{'path'}/$remotedate/$measuring->{$type}->{$_}->{tag} || exit 1\n") || die "cannot write to shell: $@";
					#$self->{channel}->flush || die $self->{log}->save('e', "cannot flush: $@");
					$self->{channel}->blocking(1) || die "cannot blocking: $@";
					select(undef, undef, undef, 0.2); # sleep 50 ms
					$self->{channel}->read($buf, BUFLEN) || die "cannot read to shell: $@";
					($timestamp, $value) = split('\x01', $buf); #\x01 -> SOH

					my ($h, $m, $s, $mls) = $timestamp =~ /^(\d{2})(\d{2})(\d{2})(\d{3})/;
					$timestamp = strftime("%Y-%m-%d ", localtime time)."$h:$m:$s.$mls";

				$values{$type}{$measuring->{$type}->{$_}->{id_measuring}} = {	'timestamp' => $timestamp,
																				'value' => $value,
																				'id_measuring' => $measuring->{$type}->{$_}->{id_measuring},
																				'unit' => $measuring->{$type}->{$_}->{unit}
																			};
				}
			}
=cut
	};# обработка ошибки
	if($@) { $self->{error} = 1;
			 $self->{log}->save('e', "$@");
			 $self->disconnect();
	}
    return(\%values);
  }

  sub _write {
	my($path, $data) = @_;
	open(my $fh, '>', $path) or die "Не могу открыть файл $!";
	print $fh $_ for @{$data};
	close $fh;
  }
}
1;

