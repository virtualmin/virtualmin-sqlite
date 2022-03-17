# Defines functions for this feature
use strict;
use warnings;
our (%text);
our $module_name;

do 'virtualmin-sqlite-lib.pl';

# feature_name()
# Returns a short name for this feature
sub feature_name
{
return $text{'feat_name'};
}

# feature_losing(&domain)
# Returns a description of what will be deleted when this feature is removed
sub feature_losing
{
return $text{'feat_losing'};
}

# feature_label(in-edit-form)
# Returns the name of this feature, as displayed on the domain creation and
# editing form
sub feature_label
{
my ($edit) = @_;
return $edit ? $text{'feat_label2'} : $text{'feat_label'};
}

# feature_check()
# Returns undef if all the needed programs for this feature are installed,
# or an error message if not
sub feature_check
{
return &get_sqlite_command() ? undef : &text('feat_echeck', "<tt>sqlite</tt>");
}

# feature_depends(&domain)
# Returns undef if all pre-requisite features for this domain are enabled,
# or an error message if not
sub feature_depends
{
return !$_[0]->{'unix'} && !$_[0]->{'parent'} ? $text{'feat_eunix'} :
       !$_[0]->{'dir'} ? $text{'feat_edir'} : undef;
}

# feature_clash(&domain)
# Returns undef if there is no clash for this domain for this feature, or
# an error message if so
sub feature_clash
{
return undef;
}

# feature_suitable([&parentdom], [&aliasdom], [&subdom])
# Returns 1 if some feature can be used with the specified alias and
# parent domains
sub feature_suitable
{
return !$_[1] && !$_[2];
}

# feature_setup(&domain)
# Called when this feature is added, with the domain object as a parameter
sub feature_setup
{
# Nothing to do ..
}

# feature_modify(&domain, &olddomain)
# Called when a domain with this feature is modified
sub feature_modify
{
# Nothing to do ..
}

# feature_delete(&domain)
# Called when this feature is disabled, or when the domain is being deleted
sub feature_delete
{
# Nothing to do ..
}

# feature_webmin(&main-domain, &all-domains)
# Returns a list of webmin module names and ACL hash references to be set for
# the Webmin user when this feature is enabled
sub feature_webmin
{
my @doms = grep { $_->{$module_name} }  @{$_[1]};
if (@doms) {
	return ( [ $module_name,
		   { 'dir' => join("\t", map { $_->{'home'} } @doms),
		     'user' => $_[0]->{'user'} } ] );
	}
else {
	return ( );
	}
}

# database_name()
# Returns the name for this type of database
sub database_name
{
return $text{'db_name'};
}

# database_list(&domain)
# Returns a list of databases owned by a domain, according to this plugin
sub database_list
{
my ($d) = @_;
my @rv;
foreach my $db (split(/\s+/, $d->{'db_'.$module_name} || "")) {
	push(@rv, { 'name' => $db,
		    'type' => $module_name,
		    'desc' => &database_name(),
		    'link' => "/$module_name/index.cgi?db=".
				&urlize("$d->{'home'}/$db.sqlite") });
	}
return @rv;
}

# databases_all([&domain])
# Returns a list of all databases on the system, possibly limited to those
# associated with some domain
sub databases_all
{
if ($_[0]) {
	return &databases_in_dir($_[0]->{'home'});
	}
else {
	return ( );
	}
}

# database_clash(&domain, name)
# Returns 1 if the named database already exists
sub database_clash
{
return -r "$_[0]->{'home'}/$_[1].sqlite";
}

# database_create(&domain, dbname)
# Creates a new database for some domain. May call the *print functions to
# report progress
sub database_create
{
my $file = "$_[0]->{'home'}/$_[1].sqlite";
&$virtual_server::first_print(&text('db_creating', "<tt>$file</tt>"));
my $sqlite = &get_sqlite_command();
my $cmd = &command_as_user($_[0]->{'user'}, 0,
			      "echo .tables | $sqlite ".quotemeta($file));
my $out = &backquote_logged("$cmd 2>&1 </dev/null");
if ($?) {
	&$virtual_server::second_print(&text('db_failed', "<tt>$out</tt>"));
	}
else {
	my @dbs = split(/\s+/, $_[0]->{'db_'.$module_name});
	push(@dbs, $_[1]);
	$_[0]->{'db_'.$module_name} = join(" ", @dbs);
	&$virtual_server::second_print($virtual_server::text{'setup_done'});
	}
}

# database_delete(&domain, dbname)
# Creates an existing database for some domain. May call the *print functions to
# report progress
sub database_delete
{
my $file = "$_[0]->{'home'}/$_[1].sqlite";
&$virtual_server::first_print(&text('db_deleting', "<tt>$file</tt>"));
unlink($file);
my @dbs = split(/\s+/, $_[0]->{'db_'.$module_name});
@dbs = grep { $_ ne $_[1] } @dbs;
$_[0]->{'db_'.$module_name} = join(" ", @dbs);
&$virtual_server::second_print($virtual_server::text{'setup_done'});
}

# database_size(&domain, dbname)
# Returns the on-disk size and number of tables in a database
sub database_size
{
my $file = "$_[0]->{'home'}/$_[1].sqlite";
my @st = stat($file);
my $sqlite = &get_sqlite_command();
my $cmd = &command_as_user($_[0]->{'user'}, 0,
			      "echo .tables | $sqlite ".quotemeta($file));
no strict "subs";
&open_execute_command(OUT, $cmd, 1);
use strict "subs";
my $tables;
while(<OUT>) {
	s/\r|\n//g;
	$tables++ if (/^\S+$/);
	}
close(OUT);
return ($st[7], $tables);
}

1;
