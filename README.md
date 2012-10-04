Mavenizer
=========

This Skript helps you mavenize your Application Server. It will scan your SOA-P Installation and put the jar files into your local maven repository. 
It does it by generating a parent pom that holds all the dependencies. for your Installation. All it needs to run is your SOA-P Installation Directory.

This Skript needs nokogiri installed. You can install it using the gem system

gem install nokogiri

It will then take jars it finds in these Directories

- /jboss-esb/client
- /jboss-esb/server/default/lib
- /jboss-esb/server/default/deploy/jbossesb.esb
- /jboss-esb/server/default/deploy/jbossesb.sar/lib
- /jboss-esb/server/default/deploy/jbpm.esb
- /jboss-esb/server/default/deploy/jbrules.esb
- /jboss-esb/server/default/deploy/smooks.esb
- /jboss-esb/server/default/deploy/soap.esb
- /jboss-esb/server/default/deploy/spring.esb
- /jboss-esb/server/default/deploy/jbossesb-registry.sar

You can adjust the paths search by modifying the script starting from Line 118. The Script itself and how you use it is straightforward, most things are configurable and I tried to document everything adequately.

	buddy:Mavenizer buddy$ ruby import_libraries.rb -h

	This Script will go through your Enterprise Installation and seek for jars at known locations
	It will then take those jars and import them into your local maven repo using mvn install:install-file
	The script will also generate a bom (see http://docs.codehaus.org/display/MAVEN/Importing+Managed+Dependencies)
	and import it into your local repo. A child pom making use of this bom is generated as well.

	Usage: import_libraries.rb [options]
	    -V, --verbose                    Be more verbose
	    -s, --soa-p-home PATH            The Home Directory of SOA-P
	    -g, --groupId STRING             The groupId to use in the maven Descriptor (defaults to "com.redhat")
	    -v, --version STRING             The version String to use in the maven Descriptor (defaults to "5.3.0-SOA-P")
	    -d, --output-directory STRING    The Output Directory for the generated client pom.xml (defaults to ".")
	    -w, --work-directory STRING      The Working Directory in which the generated bom is stored (defaults to ".")
	    -t, --dry-run                    Do not do anything, just print what would be done
	    -h, --help                       Display this screen

