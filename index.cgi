#!/usr/local/bin/perl
# Show a form for executing SQL

$unsafe_index_cgi = 1;
require './virtualmin-sqlite-lib.pl';
&ui_print_header(undef, $text{'index_title'}, "", undef, 0, 1);
%access = &get_module_acl();
@dirs = split(/\t+/, $access{'dir'});
&ReadParse();

# Show database selection form
print &ui_form_start("index.cgi", "post");
print "<table>\n";
print "<tr> <td><b>$text{'index_db'}</b></td> <td>\n";
if (@dirs) {
	foreach $dir (@dirs) {
		push(@dbs, &databases_in_dir($dir));
		}
	print &ui_select("db", $in{'db'},
		[ map { [ $_->{'file'}, $_->{'name'} ] } @dbs ]);
	}
else {
	print &ui_textbox("db", $in{'db'}, 40);
	}
print "</td> </tr>\n";

# Show SQL input
print "<tr> <td valign=top><b>$text{'index_sql'}</b></td>\n";
print "<td>",&ui_textarea("sql", $in{'sql'}, 3, 70),"</td> </tr>\n";
print "</table>\n";
print &ui_form_end([ [ "ok", $text{'index_ok'} ] ]);

if ($in{'sql'} && $in{'db'}) {
	# Show results
	print "<hr>\n";
	print &text('index_exec',
		    "<tt>".&html_escape($in{'sql'})."</tt>"),"<p>\n";
	if (@dirs) {
		$ok = 0;
		foreach $dir (@dirs) {
			$ok = 1 if (&is_under_directory($dir, $in{'db'}));
			}
		$ok || &error($text{'index_ecannot'});
		}

	if ($access{'user'}) {
		# Switch to a non-root user
		$user = $access{'user'} eq "*" ? $remote_user : $access{'user'};
		@uinfo = getpwnam($user);
		if (scalar(@uinfo)) {
			($(, $)) = ( $uinfo[3],
				     "$uinfo[3] ".join(" ", $uinfo[3],
					       &other_groups($uinfo[0])) );
			($>, $<) = ( $uinfo[2], $uinfo[2] );
			}
		else {
			&error("User $user does not exist!");
			}
		}

	# Run the SQL
	use DBI;
	$drh = DBI->install_driver("SQLite2");
	$dbh = $drh->connect($in{'db'}, undef, undef, { });
	$dbh || &error(&text('index_eopen', $drh->errstr));
	$cmd = $dbh->prepare($in{'sql'});
	$cmd || &error(&text('index_esql', $dbh->errstr));
	($rv = $cmd->execute()) || &error(&text('index_esql', $dbh->errstr));
	while(my @r = $cmd->fetchrow()) {
		push(@rows, \@r);
		}
	@titles = @{$cmd->{'NAME'}};
	$cmd->finish();
	$dbh->commit();
	$dbh->disconnect();

	# Print output
	print &ui_columns_table(\@titles, undef, \@rows, undef, 0, undef,
			        &text('index_none', int($rv)));
	}

&ui_print_footer("/", $text{'index'});

