package _ssh;{
  use strict;
  use warnings;
  use utf8;
  use lib 'libs';
  use parent "ssh";
  use constant BUFLEN => 10_0000;
  use Data::Dumper;

  sub read_file {
    my($self, $measuring) = @_;
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
}
1;

