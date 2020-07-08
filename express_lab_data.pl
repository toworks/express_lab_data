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
	my $ssh = _ssh->new($log);
	$ssh->set('DEBUG' => $DEBUG);
	$ssh->set('host' => $conf->get('ssh')->{host});
	$ssh->set('port' => $conf->get('ssh')->{port});
	$ssh->set('user' => $conf->get('ssh')->{user});
	$ssh->set('password' => $conf->get('ssh')->{password});


	$ssh->connect;
	print Dumper($ssh);
	$ssh->read_file;
	
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

