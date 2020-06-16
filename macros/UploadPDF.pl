################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2020 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/UploadImage.pl,v 1.0 2020/05/28 23:28:44 gage Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=pod

=head1 NAME

UploadPDF.pl

=head1 SYNOPSIS

Provides students a way to upload a single PDF (for example, of rough work for partial credit) to a WeBWorK question.

=head1 DESCRIPTION

Load the C<UploadPDF.pl> macro file.

=over 12

=item loadMacros("PGstandard.pl","MathObjects.pl","PGML.pl","UploadImages.pl","PGcourse.pl");

=back

The C<UploadImages.pl> macro file has one Perl subroutine C<UploadImages()> that is run in
Perl mode (not inside a BEGIN_TEXT / END_TEXT or a
BEGIN_PGML / END_PGML block).

=over 12

=item C<UploadPDF()>

=back

Insert a PDF upload prompt using

=over 12

BEGIN_TEXT
The text of the problem goes here.
END_TEXT

UploadPDF(); # creates its own text and html

=back

This sends the files to a separate cgi script which is allowed to write to disc.

Warning: the preview button only shows that the webpage recieved the PDF file, it does not guarantee that the helper 
script wrote it to disc successfully.

=head1 MANUAL LOCAL INSTALLATION FOR ONE COURSE

You need to have root access to install UploadPDF.pm in 

/opt/webwork/pg/lib

Anyone with professor level permissions can move 
C<UploadPDF.pl> to the C<course/templates/macros/> directory using the 
File Manager in the WeBWorK graphical user interface as follows: 

1. Click File Manager.  This will put you into the C<course/templates/> directory.
2. Double click the C<macros/> directory.
3. Choose the C<UploadPDF.pl> file from your hard drive and press C<Upload>.


=head1 MANUAL SYSTEM WIDE INSTALLATION

Move the file C<UploadPDF.pl> to 
    
        /opt/webwork/pg/macros/UploadPDF.pl

and the file C<UploadPDF.pm> to

	/opt/webwork/pg/lib/UploadPDF.pm

=head1 AUTHORS

Joseph Maher, CUNY CSI, Department of Mathematics

based on UploadImages.pl by Paul Pearson, Hope College, Department of Mathematics and Statistics

=cut




########################################################

sub _UploadPDF_init {}; # don't reload this file

HEADER_TEXT(<<END_HEADER_TEXT);	

<script>

// base64 encodes a file
function getBase64(file, onLoadCallback) {
    return new Promise(function(resolve, reject) {
        var reader = new FileReader();
        reader.onload = function() { resolve(reader.result); };
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

async function uploadFile() {

    var files = document.querySelector('input[name="file"]').files;

    let file = files[0];

    if ( file.size > 10*1024*1024 ) {
	alert("File too big.");
	return false;
    }

    // for the preview make a URL pointing to the local copy of the file
    _OBJECT_URL = URL.createObjectURL(file);
    document.getElementById('hidden_pdf_file_url').value = _OBJECT_URL;

    // base64 encode the file and put it in a hidden input field 
    var promise = getBase64(file);
    document.getElementById('hidden_pdf_file_base64').value = await promise;

    // set up the preview
    var preview = document.querySelector('#preview');

    // Create anchor element. 
    var a = document.createElement('a');  
                  
    // Create the text node for anchor element. 
    var link = document.createTextNode("Preview"); 
                  
    // Append the text node to anchor element. 
    a.appendChild(link);  
                  
    // Set the title. 
    a.title = "Preview";  
                  
    // Set the href property. 
    a.href = _OBJECT_URL;    
    a.target="_blank";
                  
    // Append the anchor element to the preview element. 
    preview.appendChild(a);

    // <input id="uploadPDF_id" name="uploadPDF" onclick="this.form.target='_self'" type="submit" value="Upload PDF">
    var b = document.createElement('input');
    b.id = "uploadPDF_id";
    b.name = "uploadPDF";
    b.onclick = "this.form.target='_self'";
    b.type="submit";
    b.value="Upload PDF";
    preview.appendChild(b);
}

</script>

END_HEADER_TEXT



###########################################

sub UploadPDF {

$course = $main::courseName;
#$user = $main::inputs_ref->{effectiveUser}; # would like to use this but web user editable
$user = $main::studentLogin;
$problem = $main::probNum;
$set = $main::setNumber;
$file = $main::inputs_ref->{hidden_pdf_file_base64};

my $html = qq(
    $PAR
    $HR
    $PAR
	);

main::TEXT(main::MODES(TeX=>"", HTML=>$html, PTX=>$html));


# only allow uploads until the due date 
if ( time() < $main::dueDate ) {

	# when the upload button is pressed the page is reloaded and $file should be non-empty
	if ($file ) {
		UploadPDF::savePDF($course, $set, $user, $problem, $file);
	}

	# show the upload box

	my $html = qq(
    <h4 style="margin:0">You may attach a single pdf file</h4>
    <input type="hidden" name="hidden_pdf_file_url" id="hidden_pdf_file_url" value="" />
    <input type="hidden" name="hidden_pdf_file_base64" id="hidden_pdf_file_base64" value="" />
    $PAR
    <input type="file" name="file" accept="application/pdf" onchange="uploadFile()" /> 
    <a id="preview"></a>
    	);

	main::TEXT(main::MODES(TeX=>"", HTML=>$html, PTX=>$html));
}

# let the user know if there is a file on disk
if ( UploadPDF::fileExists($course, $set, $user, $problem) ) {

	my $html = qq(
    $PAR
    PDF File uploaded.
    $HR
	);

	main::TEXT(main::MODES(TeX=>"", HTML=>$html, PTX=>$html));
}

} # end UploadPDF()


1;
