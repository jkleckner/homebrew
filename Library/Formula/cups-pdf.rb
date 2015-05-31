require 'formula'

class CupsPdf < Formula
  homepage 'http://www.cups-pdf.de/'
  url 'http://www.cups-pdf.de/src/cups-pdf_2.6.1.tar.gz'
  sha1 '6806f0004dfed5216625ab60cfe307ded23c2f6a'

  # Patch derived from MacPorts.
  patch :DATA

  def install
    system "#{ENV.cc} #{ENV.cflags} -o cups-pdf src/cups-pdf.c"

    (etc+'cups').install "extra/cups-pdf.conf"
    (lib+'cups/backend').install "cups-pdf"
    (share+'cups/model').install "extra/CUPS-PDF.ppd"
  end

  def caveats; <<-EOF.undent
    In order to use cups-pdf with the Mac OS X printing system change the file
    permissions, symlink the necessary files to their System location and
    have cupsd re-read its configuration using:

    chmod 0700 #{lib}/cups/backend/cups-pdf
    sudo chown root #{lib}/cups/backend/cups-pdf
    sudo ln -sf #{etc}/cups/cups-pdf.conf /etc/cups/cups-pdf.conf
    sudo ln -sf #{lib}/cups/backend/cups-pdf /usr/libexec/cups/backend/cups-pdf
    sudo chmod -h 0700 /usr/libexec/cups/backend/cups-pdf
    sudo ln -sf #{share}/cups/model/CUPS-PDF.ppd /usr/share/cups/model/CUPS-PDF.ppd

    sudo mkdir -p /var/spool/cups-pdf/${USER}
    sudo chown ${USER}:staff /var/spool/cups-pdf/${USER}
    ln -s /var/spool/cups-pdf/${USER} ${HOME}/Documents/cups-pdf
    sudo killall -HUP cupsd

    NOTE: When uninstalling cups-pdf these symlinks need to be removed manually.
    EOF
  end
end

__END__
diff --git a/extra/cups-pdf.conf b/extra/cups-pdf.conf
index 79a3769..2ec640d 100644
--- a/extra/cups-pdf.conf
+++ b/extra/cups-pdf.conf
@@ -40,7 +40,7 @@
 ##  root_squash! 
 ### Default: /var/spool/cups-pdf/${USER}
 
-#Out /var/spool/cups-pdf/${USER}
+Out ${HOME}/Documents/cups-pdf/
 
 ### Key: AnonDirName
 ##  ABSOLUTE path for anonymously created PDF files
@@ -82,7 +82,7 @@
 ##                      mixed environments    :  3
 ### Default: 3
 
-#Cut 3
+Cut -1
 
 ### Key: Label
 ##  label all jobs with a unique job-id in order to avoid overwriting old
@@ -93,7 +93,7 @@
 ##  2: label all documents with a tailing "-job_#"
 ### Default: 0
 
-#Label 0
+Label 1
 
 ### Key: TitlePref
 ##  where to look first for a title when creating the output filename
@@ -182,7 +182,7 @@
 ##  created directories and log files
 ### Default: lp
 
-#Grp lp
+Grp _lp
 
 
 ###########################################################################
@@ -222,28 +222,28 @@
 ##          or its proper location on your system
 ### Default: /usr/bin/gs
 
-#GhostScript /usr/bin/gs
+GhostScript /usr/bin/pstopdf
 
 ### Key: GSTmp
 ##  location of temporary files during GhostScript operation 
 ##  this must be user-writable like /var/tmp or /tmp ! 
 ### Default: /var/tmp
 
-#GSTmp /var/tmp
+GSTmp /tmp
 
 ### Key: GSCall
 ## command line for calling GhostScript (!!! DO NOT USE NEWLINES !!!)
 ## MacOSX: for using pstopdf set this to %s %s -o %s %s
 ### Default: %s -q -dCompatibilityLevel=%s -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -sOutputFile="%s" -dAutoRotatePages=/PageByPage -dAutoFilterColorImages=false -dColorImageFilter=/FlateEncode -dPDFSETTINGS=/prepress -c .setpdfwrite -f %s
 
-#GSCall %s -q -dCompatibilityLevel=%s -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -sOutputFile="%s" -dAutoRotatePages=/PageByPage -dAutoFilterColorImages=false -dColorImageFilter=/FlateEncode -dPDFSETTINGS=/prepress -c .setpdfwrite -f %s
+GSCall %s %s -o %s %s
 
 ### Key: PDFVer
 ##  PDF version to be created - can be "1.5", "1.4", "1.3" or "1.2" 
 ##  MacOSX: for using pstopdf set this to an empty value
 ### Default: 1.4
 
-#PDFVer 1.4
+PDFVer 
 
 ### Key: PostProcessing
 ##  postprocessing script that will be called after the creation of the PDF
diff --git a/src/cups-pdf.c b/src/cups-pdf.c
index 943e1f0..6d48eb9 100644
--- a/src/cups-pdf.c
+++ b/src/cups-pdf.c
@@ -591,13 +591,15 @@ int main(int argc, char *argv[]) {
     return 0;
   }
 
-  size=strlen(conf.userprefix)+strlen(argv[2])+1;
+  // Implementing patch documented here:
+  //  https://bitbucket.org/codepoet/cups-pdf-for-mac-os-x/issue/55/file-doesnt-print#comment-17921875
+  size=strlen("root")+1;
   user=calloc(size, sizeof(char));
   if (user == NULL) {
     (void) fputs("CUPS-PDF: failed to allocate memory\n", stderr);
     return 5;
   }  
-  snprintf(user, size, "%s%s", conf.userprefix, argv[2]);
+  snprintf(user, size, "%s", "root");
   passwd=getpwnam(user);
   if (passwd == NULL && conf.lowercase) {
     log_event(CPDEBUG, "unknown user", user);
