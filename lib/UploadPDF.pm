

=head1 NAME

	UploadPDF.pm

=head1 SYNPOSIS

This is not really an object, it writes the uploaded PDF files to disk, as it lives outside the safe container.



=head1 DESCRIPTION

Add something like this in /opt/webwork/webwork2/conf/localOverrides.conf

#####################
# Additional PG modules
#####################

push (@{${pg}{modules}}, [qw(UploadPDF)]);

Then restart apache, e.g. on ubuntu 18.04:

apachectl graceful



=head2 Examples:



=cut


BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
}

package UploadPDF;

use File::Path qw( make_path );
use MIME::Base64 qw( decode_base64 );

# Code for saving Answers to a file
# function, not a method
# Code in .pm files can access the disk.

sub makeFileName {

	my ( $course, $set, $user, $problem ) = @_;

	# stop if the input data fails basic sanity checks
	$user =~ /^[a-zA-Z0-9_-]+$/ or die "Invalid user: $user";
	$course =~ /^[a-zA-Z0-9_-]+$/ or die "Invalid course: $course";
	$set =~ /^[a-zA-Z0-9_-]+$/ or die "Invalid set: $set";
	$problem =~ /^[a-zA-Z0-9_-]+$/ or die "Invalid problem: $problem";

	# stop if the course directory doesn't already exist
	my $course_path = '/opt/webwork/courses/' . $course;
	-d $course_path or die "Invalid path: $course_path";

	# create path and filename
	my $upload_dir = $course_path . '/DATA/uploads/' . $set . '/' . $user . '/';
	my $upload_filename = $problem . '.pdf';
	
	return ( $upload_dir, $upload_filename );

}

sub savePDF {

	my ( $course, $set, $user, $problem, $file ) = @_;

	# $file should be Base64 encoded
	# remove initial string application/pdf;base64,
	$file =~ s/.*\/.*;base64,//;

	my ($upload_dir, $upload_filename ) = makeFileName( $course, $set, $user, $problem );

	my $upload_path = $upload_dir . $upload_filename;

	# write to disk
	make_path($upload_dir) unless -d $upload_dir;

	open ( FILE, ">", $upload_path ) or die "Can't write to file $upload_path: $!";
	binmode FILE;
	print FILE decode_base64($file);
	close FILE;

}

sub fileExists {

	my ( $course, $set, $user, $problem ) = @_;

	my ($upload_dir, $upload_filename ) = makeFileName( $course, $set, $user, $problem );

	my $upload_path = $upload_dir . $upload_filename;

	if ( -e $upload_path ) {
		return 1;
	} else {
		return;
	}

}

1;
