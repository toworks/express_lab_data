#0!/usr/bin/perl

 use strict;
 use warnings;
 use utf8;
 binmode(STDOUT,':utf8');
 use open(':encoding(utf8)');
 use Data::Dumper;  
 use threads;
 use threads::shared;
 use Time::HiRes qw(time);
 use POSIX qw(strftime);
 use LWP::UserAgent;
 use lib ('libs', '.');
 use logging;
 use configuration;
 use _ssh;

# my $DEBUG: shared;
# my %TASKS: shared;
# my $task_count: shared;
 
 $| = 1;  # make unbuffered

 my $VERSION = "0.1 (20200708)";
 my $log = LOG->new();
 my $conf = configuration->new($log);

 $log->save('i', "program version: ".$VERSION);

 my $DEBUG = $conf->get('app')->{'debug'};

## $SIG{'TERM'} = $SIG{'HUP'} = $SIG{'INT'} = sub {
##                      local $SIG{'TERM'} = 'IGNORE';
#						$log->save('d', "SIGNAL TERM | HUP | INT | $$");
##					  $log->save('i', "program stopped");
##                      kill TERM => -$$;
## };


 # execute
 threads->new(\&execute, $$, $conf, $log);


 # main loop
 {
   while (threads->list()) {
#        $log->save('d', "thread main");
       sleep(1);
       if ( ! threads->list(threads::running) ) {
#            $daemon->remove_pid();
           $SIG{'TERM'} = 'DEFAULT'; # Восстановить стандартный обработчик
           kill TERM => -$$;
		   $log->save('i', "PID $$");
        }
    }
  }


 sub execute {
    my($id, $conf, $log) = @_;
    $log->save('i', "start thread pid $id");

	# ssh create object
	my $ssh_read = _ssh->new($log);
	$ssh_read->set('DEBUG' => $DEBUG);
	$ssh_read->set('host' => $conf->get('read')->{ssh}->{host});
	$ssh_read->set('port' => $conf->get('read')->{ssh}->{port});
	$ssh_read->set('user' => $conf->get('read')->{ssh}->{user});
	$ssh_read->set('password' => $conf->get('read')->{ssh}->{password});


	$ssh_read->connect;
	print Dumper($ssh_read);
	my $data = $ssh_read->read($conf->get('read')->{ssh}->{remote_folder});
	
	#print Dumper($data);
	
	#&write($conf->get('read')->{ssh}->{local_folder}, $data);

	#$ssh_read->write($conf->get('read')->{ssh}->{remote_folder}, $data);
	$ssh_read->write('ee/', $data);
	#$ssh_read->disconnect;
	
	print $_ for keys %{$data};
	$ssh_read->delete('ee/', $_) for keys %{$data};
	exit;
=comm
	while (1) {

		my $weight = $reader->read();
		my $status = ( defined($reader->get('stab')) ? $reader->get('stab') : 1);

		$log->save('i', $conf->{'measuring'}->{id_scale}. ", " .
						strftime("%Y-%m-%d %H:%M:%S", localtime time) .
						" status: $status, $weight" ) if defined($weight) and (ref $weight ne 'ARRAY') and $DEBUG;
		$log->save('i', $conf->{'measuring'}->{id_scale}. ", " .
						strftime("%Y-%m-%d %H:%M:%S", localtime time) .
						" status: $status, weight: ". join(" | ", @{$weight}) )  if defined($weight) and (ref $weight eq 'ARRAY') and $DEBUG;
		print $conf->{'measuring'}->{id_scale}. ", " .
						strftime("%Y-%m-%d %H:%M:%S", localtime time) .

						" status: $status, $weight","\n" if defined($weight) and (ref $weight ne 'ARRAY') and $DEBUG;
		print $conf->{'measuring'}->{id_scale}. ", " .
						strftime("%Y-%m-%d %H:%M:%S", localtime time) .
						" status: $status, weight: ", join(" | ", @{$weight}), "\n" if defined($weight) and (ref $weight eq 'ARRAY') and $DEBUG;

		$sql->write_weight( ($conf->{'measuring'}->{id_scale}, strftime("%Y-%m-%d %H:%M:%S", localtime time), $status, $weight) ) if defined($weight);

        print "cycle: ",$conf->{'cycle'}, "\n" if $DEBUG;
        select undef, undef, undef, $conf->{'cycle'} || 10;
	}
=cut
 }

 sub write {
	my($folder, $data) = @_;
	foreach my $filename ( keys %{$data} ) {
		my $path = $folder.$filename if defined($folder);
		$log->save('i', $filename . "\t" . Dumper($data->{$filename})) if $DEBUG;
		open(my $fh, '>', $path) || die $log->save('d', "Unable to open file: $!");
		print $fh $_."\r\n" for @{$data->{$filename}};
		close $fh;
	}
 }
