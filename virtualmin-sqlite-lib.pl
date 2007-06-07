# Functions for the SQLite database

do '../web-lib.pl';
&init_config();
do '../ui-lib.pl';

sub databases_in_dir
{
local @rv;
opendir(DIR, $_[0]);
while(my $f = readdir(DIR)) {
	if ($f =~ /^(\S+)\.sqlite$/) {
		push(@rv, { 'name' => $1,
			    'type' => $module_name,
			    'file' => "$_[0]/$f",
			    'desc' => $text{'db_name'} });
		}
	}
closedir(DIR);
return @rv;
}

1;

