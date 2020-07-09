#0!/usr/bin/perl

 use strict;
 use warnings;
 use utf8;
 binmode(STDOUT,':utf8');
 use open(':encoding(utf8)');
 use Data::Dumper;  
 use threads;
 use threads::shared;
 use Time::HiRes qw(gettimeofday tv_interval time);
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
	my $ssh_in = _ssh->new($log);
	$ssh_in->set('DEBUG' => $DEBUG);
	$ssh_in->set('host' => $conf->get('in')->{ssh}->{host});
	$ssh_in->set('port' => $conf->get('in')->{ssh}->{port});
	$ssh_in->set('user' => $conf->get('in')->{ssh}->{user});
	$ssh_in->set('password' => $conf->get('in')->{ssh}->{password});


	# ssh create object
	my $ssh_out = _ssh->new($log);
	$ssh_out->set('DEBUG' => $DEBUG);
	$ssh_out->set('host' => $conf->get('out')->{ssh}->{host});
	$ssh_out->set('port' => $conf->get('out')->{ssh}->{port});
	$ssh_out->set('user' => $conf->get('out')->{ssh}->{user});
	$ssh_out->set('password' => $conf->get('out')->{ssh}->{password});
	
	$ssh_in->connect;
	$ssh_out->connect;
	
	print Dumper($ssh_in);
	while (1) {
		
		my $t0 = [gettimeofday];
		
		my $data = $ssh_in->read($conf->get('in')->{ssh}->{remote_folder});

		$ssh_in->delete($conf->get('in')->{ssh}->{remote_folder}, $_) for keys %{$data};
		
		#print Dumper($data);
		
		&write($conf->get('in')->{ssh}->{local_folder}, $data);


		#$ssh_in->write($conf->get('in')->{ssh}->{remote_folder}, $data);
		$ssh_in->write($conf->get('out')->{ssh}->{remote_folder}, $data);
		#$ssh_in->disconnect;
		
		print $_, "\n" for keys %{$data};
	
=comm

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
=cut
		my $t1 = [gettimeofday];
		my $tbetween = tv_interval $t0, $t1;
		my $cycle;
		if ( $tbetween < $conf->get('app')->{'cycle'} ) {
			$cycle = $conf->get('app')->{'cycle'} - $tbetween;
		} else {
			$cycle = 0;
		}

		$log->save('d', "cycle:  setting: ". $conf->get('app')->{'cycle'} ."  current: ". $cycle) if $DEBUG;
        print "cycle:  setting: ", $conf->get('app')->{'cycle'}, "  current: ", $cycle, "\n" if $DEBUG;
        select undef, undef, undef, $cycle;

	}
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
