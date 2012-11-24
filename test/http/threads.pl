#! perl -w

use threads ('yield',
	'stack_size' => 64*4096,
	'exit' => 'threads_only',
	'stringify');

sub start_thread {
my @args = @_;
print('Thread started: ', join(' ', @args), "\n");
}
my $thr = threads->create('start_thread', @ARGV);
$thr->join();