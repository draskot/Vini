#!/usr/bin/perl -w

BEGIN {
    use strict;
    use File::Slurp;
}


# ------------------------------------------------------------------------------
#
# This script recursively scans the current directory for files (.py).  For each
# file, it sifts through the 'git blame' output to derive authorship and
# lifetime information -- those are then stored at the begin of the file, as  
#
#   __author__    = "$PROJECT ($authors)"
#   __copyright__ = "Copyright $years, RADICAL@Rutgers"
#   __license__   = "MIT"
#
# The script will ignore authorship for empty lines, and for the lines above.
# $PROJECT is read from a file './PROJECT', which must exist.
#

my $PROJECT = `cat PROJECT | head -n 1`;
chomp $PROJECT;

$PROJECT || die "no file 'PROJECT'?\n";

my $base = $PROJECT;
$base =~ tr/[A-Z]/[a-z]/;
$base =~ s/^([a-z0-9]*).*$/$1/;

my @dirs = ($base, 'doc', 'docs', 'examples', 'tests', 'src');

# find all files we want to check
my @files = ();

foreach my $dir ( @dirs )
{
  push (@files, split (/\n/, `find $dir -type f -name \\*.py 2>/dev/null`));
}

# snippets for blame command to find authorship
my $blame    = "git blame -M -C -C -C -c -w";
my $authgrep = "grep -v -e '^.*) *__\\(author\\|copyright\\|license\\)__' " .
"-e 'Committed' " .
"-e '^[^)]*) *\$' " .
"-e '^[^)]*) *# *vim *.*\$'";
my $authcut  = "cut -f 2- -d '(' | cut -f 1 -d '2'"; # relies on year>=2000
my $yearcut  = "cut -f 2  -d '(' | cut -f 1 -d ')' | " . 
"cut -f 1  -d ':' | rev | cut -c 10-13 | rev | grep -ve '^ *\$' ";



FILE:
for my $file ( @files )
{
    print "$file\n";

    # run the blame 3 times, to get authors, first year of commit, and last.  Yes,
    # this is inefficient, but the code is ugly as is, so we leave optimizations
    # out for now...
    my @authors   = split (/\n/, `$blame $file | $authgrep | $authcut | sort -u`);
    my $first     =              `$blame $file |             $yearcut | sort -un | head -1`;
    my $last      =              `$blame $file |             $yearcut | sort -un | tail -1`;

    # get rid of newlines
    chomp (@authors);
    chomp ($first);
    chomp ($last);

    # fix some author names, and convert them to a comma separated list
    my %authors = ();
    for my $author ( @authors )
    {
        $author =~ s/^\s*(.*?)\s*$/$1/g;
        if ( $author eq "amerzky"           or
             $author eq "andre.merzky"      or
             $author eq "andre\@merzky.net" )
        {
            $author = "Andre Merzky";
        }
        $authors{$author} += 1
    }


    # build the year string
    my $years = "$first-$last";
    if ( $first eq $last )
    {
        $years = $first;
    }


    # now we need to replace or to add the new copyright header.  So we slurp the
    # file, and skip all files which are either empty or contain the old copyright
    # header.  Once that is found, we create a new list of lines from the new
    # copyright statement, and the same exact list of files, which is then written
    # back to disk.

    my @old_lines   = read_file ($file);
    my @new_lines   = ();
    my $begin       = 1;  # we only skip the first part....
    my @old_authors = (); # never remove an author
    my $old_aline   = ""; 

    OLD_LINE:
    for my $old_line ( @old_lines )
    {
        if ( $begin )
        {
            # still searching for the first valid line (non-empty, non-copyright...)
            if ( $old_line =~ /^\s*$/io )
            {
                next OLD_LINE;
            }
            if ( $old_line =~ /^\s*__(author|copyright|license)__\s*=\s*"(.*?)"\s*$/io )
            {
                my $key = $1;
                my $val = $2 || "";

                if ( $key eq 'author' ) 
                {
                    if ( $val =~ /^.*\((.+?)\)\s*$/o )
                    {
                        $val = $1;
                    }

                    @old_authors = split (/, */, $val);
                    $old_aline   = $old_line;

                    for my $old_author ( @old_authors )
                    {
                        $authors{$old_author}++;
                    }
                }

                next OLD_LINE;
            }

            my $authors = "";
            for my $author ( sort keys (%authors) )
            {
                $authors .= "$author, ";
            }
            $authors =~ s/,\s*$//g;

            my $new_aline = "__author__    = \"$PROJECT Development Team ($authors)\"\n";

            # found a 'real' line -- make sure we have the copyright statement, and
            # the found line.
            $begin = 0;
            push (@new_lines, "\n");
            push (@new_lines, "__author__    = \"$PROJECT Development Team ($authors)\"\n");
            push (@new_lines, "__copyright__ = \"Copyright $years, RADICAL\@Rutgers\"\n");
            push (@new_lines, "__license__   = \"MIT\"\n");
            push (@new_lines, "\n");
            push (@new_lines, "\n");
            push (@new_lines, $old_line);
        }
        else
        {
            # not searching anymore -- simply append all further lines.
            push (@new_lines, $old_line);
        }
    }

    # the file is re-assembled with the new copyright statement -- dump to disk.
    write_file ("$file", @new_lines);
}

